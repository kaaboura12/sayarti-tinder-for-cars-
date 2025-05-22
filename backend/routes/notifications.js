const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const { pool } = require('../config/db');
const authMiddleware = require('../middleware/auth');

// Get all notifications for current user with pagination
router.get('/', authMiddleware, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    
    const notifications = await Notification.getByUserId(req.user.id, page, limit);
    res.json(notifications);
  } catch (error) {
    console.error('Error in GET /notifications:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get count of unread notifications
router.get('/unread/count', authMiddleware, async (req, res) => {
  try {
    const count = await Notification.countUnread(req.user.id);
    res.json({ count });
  } catch (error) {
    console.error('Error in GET /notifications/unread/count:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Mark a notification as read
router.put('/:notificationId/read', authMiddleware, async (req, res) => {
  try {
    const notificationId = parseInt(req.params.notificationId, 10);
    
    if (isNaN(notificationId) || notificationId <= 0) {
      return res.status(400).json({ message: 'Invalid notification ID' });
    }
    
    // Verify notification belongs to user
    const [notificationRows] = await pool.execute(
      'SELECT * FROM notifications WHERE id = ? AND user_id = ?',
      [notificationId, req.user.id]
    );
    
    if (notificationRows.length === 0) {
      return res.status(404).json({ message: 'Notification not found or not authorized' });
    }
    
    const updated = await Notification.markAsRead(notificationId);
    
    if (updated) {
      res.json({ message: 'Notification marked as read' });
    } else {
      res.status(500).json({ message: 'Failed to mark notification as read' });
    }
  } catch (error) {
    console.error(`Error in PUT /notifications/${req.params.notificationId}/read:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Mark all notifications as read
router.put('/read-all', authMiddleware, async (req, res) => {
  try {
    const count = await Notification.markAllAsRead(req.user.id);
    res.json({ message: `${count} notifications marked as read` });
  } catch (error) {
    console.error('Error in PUT /notifications/read-all:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Delete a notification
router.delete('/:notificationId', authMiddleware, async (req, res) => {
  try {
    const notificationId = parseInt(req.params.notificationId, 10);
    
    if (isNaN(notificationId) || notificationId <= 0) {
      return res.status(400).json({ message: 'Invalid notification ID' });
    }
    
    // Verify notification belongs to user
    const [notificationRows] = await pool.execute(
      'SELECT * FROM notifications WHERE id = ? AND user_id = ?',
      [notificationId, req.user.id]
    );
    
    if (notificationRows.length === 0) {
      return res.status(404).json({ message: 'Notification not found or not authorized' });
    }
    
    const deleted = await Notification.delete(notificationId);
    
    if (deleted) {
      res.json({ message: 'Notification deleted' });
    } else {
      res.status(500).json({ message: 'Failed to delete notification' });
    }
  } catch (error) {
    console.error(`Error in DELETE /notifications/${req.params.notificationId}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router; 