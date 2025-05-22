const { pool } = require('../config/db');
const Conversation = require('./Conversation');
const Notification = require('./Notification');

class Message {
  // Get all messages for a specific conversation with pagination
  static async getByConversationId(conversationId, page = 1, limit = 50) {
    try {
      const offset = (page - 1) * limit;
      
      const [rows] = await pool.execute(
        `SELECT m.*, 
          s.name AS sender_name, s.firstname AS sender_firstname,
          r.name AS receiver_name, r.firstname AS receiver_firstname
         FROM messages m
         JOIN users s ON m.sender_id = s.id
         JOIN users r ON m.receiver_id = r.id
         WHERE m.conversation_id = ?
         ORDER BY m.created_at ASC
         LIMIT ? OFFSET ?`,
        [conversationId, limit, offset]
      );
      
      return rows;
    } catch (error) {
      console.error('Error fetching messages by conversation ID:', error);
      throw error;
    }
  }
  
  // Count messages in a conversation
  static async countByConversationId(conversationId) {
    try {
      const [rows] = await pool.execute(
        'SELECT COUNT(*) as count FROM messages WHERE conversation_id = ?',
        [conversationId]
      );
      
      return rows[0].count;
    } catch (error) {
      console.error('Error counting messages:', error);
      throw error;
    }
  }
  
  // Create a new message and update the conversation
  static async create(messageData) {
    const { sender_id, receiver_id, car_id, message } = messageData;
    
    try {
      // Start a transaction to ensure data consistency
      const connection = await pool.getConnection();
      await connection.beginTransaction();
      
      try {
        // Get or create conversation
        const conversation = await Conversation.getOrCreate(sender_id, receiver_id, car_id);
        
        // Insert the message with conversation ID
        const [msgResult] = await connection.execute(
          'INSERT INTO messages (conversation_id, sender_id, receiver_id, car_id, message) VALUES (?, ?, ?, ?, ?)',
          [conversation.id, sender_id, receiver_id, car_id, message]
        );
        
        const messageId = msgResult.insertId;
        
        // Update conversation's last message and activity
        await connection.execute(
          `UPDATE conversations 
           SET last_message_id = ?, last_activity = CURRENT_TIMESTAMP
           WHERE id = ?`,
          [messageId, conversation.id]
        );
        
        // Commit the transaction
        await connection.commit();
        
        // Get user information for the response
        const [userRows] = await pool.execute(
          `SELECT 
            s.name AS sender_name, s.firstname AS sender_firstname,
            r.name AS receiver_name, r.firstname AS receiver_firstname
           FROM users s, users r
           WHERE s.id = ? AND r.id = ?`,
          [sender_id, receiver_id]
        );
        
        const userInfo = userRows[0] || {};
        
        // Create notification for the receiver (after transaction to ensure message is saved)
        try {
          await Notification.createMessageNotification(
            receiver_id, 
            sender_id, 
            conversation.id, 
            message
          );
        } catch (notifError) {
          console.error('Error creating message notification:', notifError);
          // Don't throw this error as the message was already saved successfully
        }
        
        return { 
          id: messageId,
          conversation_id: conversation.id,
          sender_id,
          receiver_id,
          car_id,
          message,
          created_at: new Date(),
          sender_name: userInfo.sender_name,
          sender_firstname: userInfo.sender_firstname,
          receiver_name: userInfo.receiver_name,
          receiver_firstname: userInfo.receiver_firstname
        };
      } catch (err) {
        // If an error occurred, roll back the transaction
        await connection.rollback();
        throw err;
      } finally {
        // Release the connection back to the pool
        connection.release();
      }
    } catch (error) {
      console.error('Error creating message:', error);
      throw error;
    }
  }
  
  // Mark messages as read
  static async markAsRead(conversationId, userId) {
    try {
      const [result] = await pool.execute(
        `UPDATE messages 
         SET is_read = TRUE
         WHERE conversation_id = ? AND receiver_id = ? AND is_read = FALSE`,
        [conversationId, userId]
      );
      
      return result.affectedRows;
    } catch (error) {
      console.error('Error marking messages as read:', error);
      throw error;
    }
  }
  
  // Count unread messages for a user
  static async countUnread(userId) {
    try {
      const [rows] = await pool.execute(
        'SELECT COUNT(*) as count FROM messages WHERE receiver_id = ? AND is_read = FALSE',
        [userId]
      );
      
      return rows[0].count;
    } catch (error) {
      console.error('Error counting unread messages:', error);
      throw error;
    }
  }
  
  // Delete a message
  static async delete(messageId) {
    try {
      const [result] = await pool.execute(
        'DELETE FROM messages WHERE id = ?',
        [messageId]
      );
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error deleting message:', error);
      throw error;
    }
  }
}

module.exports = Message; 