const { pool } = require('../config/db');

class Notification {
  // Get all notifications for a user with pagination
  static async getByUserId(userId, page = 1, limit = 20) {
    try {
      const offset = (page - 1) * limit;
      
      const [rows] = await pool.execute(
        `SELECT * FROM notifications
         WHERE user_id = ?
         ORDER BY created_at DESC
         LIMIT ? OFFSET ?`,
        [userId, limit, offset]
      );
      
      return rows;
    } catch (error) {
      console.error('Error fetching notifications by user ID:', error);
      throw error;
    }
  }
  
  // Count unread notifications for a user
  static async countUnread(userId) {
    try {
      const [rows] = await pool.execute(
        'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = FALSE',
        [userId]
      );
      
      return rows[0].count;
    } catch (error) {
      console.error('Error counting unread notifications:', error);
      throw error;
    }
  }
  
  // Create a new notification
  static async create({ userId, title, message, type, targetId = null }) {
    try {
      const [result] = await pool.execute(
        `INSERT INTO notifications 
         (user_id, title, message, type, target_id, is_read, created_at)
         VALUES (?, ?, ?, ?, ?, FALSE, CURRENT_TIMESTAMP)`,
        [userId, title, message, type, targetId]
      );
      
      return {
        id: result.insertId,
        user_id: userId,
        title,
        message,
        type,
        target_id: targetId,
        is_read: false,
        created_at: new Date().toISOString()
      };
    } catch (error) {
      console.error('Error creating notification:', error);
      throw error;
    }
  }
  
  // Create a message notification
  static async createMessageNotification(receiverId, senderId, conversationId, messagePreview) {
    try {
      // Ensure IDs are integers
      receiverId = parseInt(receiverId, 10);
      senderId = parseInt(senderId, 10);
      conversationId = parseInt(conversationId, 10);
      
      // Get sender name
      const [userRows] = await pool.execute(
        'SELECT firstname, name FROM users WHERE id = ?',
        [senderId]
      );
      
      if (userRows.length === 0) {
        throw new Error('Sender not found');
      }
      
      const sender = userRows[0];
      const senderName = `${sender.firstname} ${sender.name}`;
      
      // Create notification
      return await Notification.create({
        userId: receiverId,
        title: `New message from ${senderName}`,
        message: messagePreview.length > 50 ? messagePreview.substring(0, 47) + '...' : messagePreview,
        type: 'message',
        targetId: conversationId
      });
    } catch (error) {
      console.error('Error creating message notification:', error);
      throw error;
    }
  }
  
  // Mark a notification as read
  static async markAsRead(notificationId) {
    try {
      const [result] = await pool.execute(
        'UPDATE notifications SET is_read = TRUE WHERE id = ?',
        [notificationId]
      );
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error marking notification as read:', error);
      throw error;
    }
  }
  
  // Mark all notifications as read for a user
  static async markAllAsRead(userId) {
    try {
      const [result] = await pool.execute(
        'UPDATE notifications SET is_read = TRUE WHERE user_id = ? AND is_read = FALSE',
        [userId]
      );
      
      return result.affectedRows;
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
      throw error;
    }
  }
  
  // Delete a notification
  static async delete(notificationId) {
    try {
      const [result] = await pool.execute(
        'DELETE FROM notifications WHERE id = ?',
        [notificationId]
      );
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error deleting notification:', error);
      throw error;
    }
  }
}

module.exports = Notification; 