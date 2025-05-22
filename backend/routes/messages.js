const express = require('express');
const router = express.Router();
const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const User = require('../models/User');
const Car = require('../models/Car');
const Notification = require('../models/Notification');
const authMiddleware = require('../middleware/auth');

// Get all conversations for current user with pagination
router.get('/conversations', authMiddleware, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    
    const conversations = await Conversation.getByUserId(req.user.id, page, limit);
    res.json(conversations);
  } catch (error) {
    console.error('Error in GET /messages/conversations:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get messages for a specific conversation with pagination
router.get('/conversations/:conversationId', authMiddleware, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    
    // Verify the conversation exists and user is a participant
    const conversation = await Conversation.getById(conversationId);
    
    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }
    
    // Check if user is a participant in this conversation
    if (conversation.user1_id !== req.user.id && conversation.user2_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied: You are not a participant in this conversation' });
    }
    
    // Get messages
    const messages = await Message.getByConversationId(conversationId, page, limit);
    
    // Mark messages as read
    await Message.markAsRead(conversationId, req.user.id);
    
    res.json({
      conversation,
      messages,
      pagination: {
        page,
        limit,
      }
    });
  } catch (error) {
    console.error(`Error in GET /messages/conversations/${req.params.conversationId}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get or create a conversation between current user and another user for a specific car
router.get('/conversation/:userId/:carId', authMiddleware, async (req, res) => {
  try {
    const { userId, carId } = req.params;
    
    // Verify the other user exists
    const otherUser = await User.findById(userId);
    if (!otherUser) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Verify the car exists
    const car = await Car.getById(carId);
    if (!car) {
      return res.status(404).json({ message: 'Car not found' });
    }
    
    // Get or create the conversation
    const conversation = await Conversation.getOrCreate(req.user.id, userId, carId);
    
    // Get messages
    const messages = await Message.getByConversationId(conversation.id);
    
    // Mark messages as read
    await Message.markAsRead(conversation.id, req.user.id);
    
    res.json({
      conversation,
      messages
    });
  } catch (error) {
    console.error(`Error in GET /messages/conversation/${req.params.userId}/${req.params.carId}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Send a message
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { receiver_id, car_id, conversation_id, message } = req.body;
    
    // Validate required fields
    if (!message) {
      return res.status(400).json({ message: 'Message content is required' });
    }
    
    if (!conversation_id && (!receiver_id || !car_id)) {
      return res.status(400).json({ message: 'Either conversation_id or both receiver_id and car_id are required' });
    }
    
    let conversationId = conversation_id;
    let receiverId = receiver_id;
    let carId = car_id;
    
    if (!conversationId) {
      // Verify the receiver exists
      const receiver = await User.findById(receiverId);
      if (!receiver) {
        return res.status(404).json({ message: 'Receiver not found' });
      }
      
      // Verify the car exists
      const car = await Car.getById(carId);
      if (!car) {
        return res.status(404).json({ message: 'Car not found' });
      }
      
      // Get or create the conversation
      const conversation = await Conversation.getOrCreate(req.user.id, receiverId, carId);
      conversationId = conversation.id;
    } else {
      // Verify the conversation exists and user is a participant
      const conversation = await Conversation.getById(conversationId);
      
      if (!conversation) {
        return res.status(404).json({ message: 'Conversation not found' });
      }
      
      // Check if user is a participant in this conversation
      if (conversation.user1_id !== req.user.id && conversation.user2_id !== req.user.id) {
        return res.status(403).json({ message: 'Access denied: You are not a participant in this conversation' });
      }
      
      // Set receiver_id and car_id from the conversation
      receiverId = conversation.user1_id === req.user.id ? conversation.user2_id : conversation.user1_id;
      carId = conversation.car_id;
    }
    
    // Create the message
    const newMessage = await Message.create({
      sender_id: req.user.id,
      receiver_id: receiverId,
      car_id: carId,
      message
    });
    
    // Get sender info for the notification
    const sender = await User.findById(req.user.id);
    const car = await Car.getById(carId);
    
    // Create a notification for the receiver
    await Notification.create({
      userId: receiverId,
      title: 'New Message',
      message: `${sender.firstname} ${sender.name} sent you a message about ${car.title}`,
      type: 'message',
      targetId: conversationId
    });
    
    // Get Socket.io instance and connected users
    const io = req.app.get('io');
    const connectedUsers = req.app.get('connectedUsers');
    
    // Check if receiver is online
    const receiverSocketId = connectedUsers.get(receiverId.toString());
    if (receiverSocketId) {
      // Send real-time message notification
      io.to(receiverSocketId).emit('receive_message', {
        message: newMessage.message,
        senderId: req.user.id,
        senderName: `${sender.firstname} ${sender.name}`,
        carId: carId,
        conversationId: conversationId,
        messageId: newMessage.id,
        createdAt: newMessage.created_at
      });
      
      // Also send notification count update
      const unreadCount = await Notification.countUnread(receiverId);
      io.to(receiverSocketId).emit('notification_update', { count: unreadCount });
    }
    
    res.status(201).json(newMessage);
  } catch (error) {
    console.error('Error in POST /messages:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Count unread messages
router.get('/unread/count', authMiddleware, async (req, res) => {
  try {
    const count = await Message.countUnread(req.user.id);
    res.json({ count });
  } catch (error) {
    console.error('Error in GET /messages/unread/count:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Delete a conversation
router.delete('/conversations/:conversationId', authMiddleware, async (req, res) => {
  try {
    const { conversationId } = req.params;
    
    // Verify the conversation exists and user is a participant
    const conversation = await Conversation.getById(conversationId);
    
    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }
    
    // Check if user is a participant in this conversation
    if (conversation.user1_id !== req.user.id && conversation.user2_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied: You are not a participant in this conversation' });
    }
    
    // Delete the conversation (this will cascade delete all messages)
    const deleted = await Conversation.delete(conversationId);
    
    if (deleted) {
      res.json({ message: 'Conversation deleted successfully' });
    } else {
      res.status(500).json({ message: 'Failed to delete conversation' });
    }
  } catch (error) {
    console.error(`Error in DELETE /messages/conversations/${req.params.conversationId}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router; 