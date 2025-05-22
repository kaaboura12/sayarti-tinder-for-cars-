const { pool } = require('../config/db');

class Conversation {
  // Get conversation by ID
  static async getById(id) {
    try {
      const [rows] = await pool.execute(
        `SELECT c.*, 
          u1.name AS user1_name, u1.firstname AS user1_firstname, u1.numerotlf AS user1_phone,
          u2.name AS user2_name, u2.firstname AS user2_firstname, u2.numerotlf AS user2_phone,
          car.title AS car_title, 
          (SELECT cp.photo_url FROM car_photos cp WHERE cp.car_id = car.id LIMIT 1) AS car_photo
         FROM conversations c
         JOIN users u1 ON c.user1_id = u1.id
         JOIN users u2 ON c.user2_id = u2.id
         JOIN cars car ON c.car_id = car.id
         WHERE c.id = ?`,
        [id]
      );
      
      if (rows.length === 0) {
        return null;
      }
      
      const conversation = rows[0];
      return {
        ...conversation,
        car_photos: conversation.car_photo || null
      };
    } catch (error) {
      console.error('Error fetching conversation by ID:', error);
      throw error;
    }
  }
  
  // Get or create conversation between two users for a specific car
  static async getOrCreate(userId1, userId2, carId) {
    try {
      // Ensure user1_id is always the smaller ID for consistency
      const user1_id = Math.min(userId1, userId2);
      const user2_id = Math.max(userId1, userId2);
      
      // Check if conversation already exists
      const [existingRows] = await pool.execute(
        `SELECT * FROM conversations 
         WHERE car_id = ? AND user1_id = ? AND user2_id = ?`,
        [carId, user1_id, user2_id]
      );
      
      if (existingRows.length > 0) {
        return existingRows[0];
      }
      
      // Create new conversation
      const [result] = await pool.execute(
        `INSERT INTO conversations (car_id, user1_id, user2_id)
         VALUES (?, ?, ?)`,
        [carId, user1_id, user2_id]
      );
      
      return {
        id: result.insertId,
        car_id: carId,
        user1_id,
        user2_id,
        last_message_id: null,
        created_at: new Date()
      };
    } catch (error) {
      console.error('Error getting or creating conversation:', error);
      throw error;
    }
  }
  
  // Get all conversations for a user with pagination
  static async getByUserId(userId, page = 1, limit = 20) {
    try {
      const offset = (page - 1) * limit;
      
      const [rows] = await pool.execute(
        `SELECT c.*,
          u1.name AS user1_name, u1.firstname AS user1_firstname,
          u2.name AS user2_name, u2.firstname AS user2_firstname,
          car.title AS car_title, 
          (SELECT cp.photo_url FROM car_photos cp WHERE cp.car_id = car.id LIMIT 1) AS car_photo,
          m.message AS last_message, m.created_at AS last_message_time,
          m.sender_id AS last_message_sender_id
         FROM conversations c
         JOIN users u1 ON c.user1_id = u1.id
         JOIN users u2 ON c.user2_id = u2.id
         JOIN cars car ON c.car_id = car.id
         LEFT JOIN messages m ON c.last_message_id = m.id
         WHERE c.user1_id = ? OR c.user2_id = ?
         ORDER BY c.last_activity DESC
         LIMIT ? OFFSET ?`,
        [userId, userId, limit, offset]
      );
      
      return rows.map(row => {
        // Determine which user is the "other" user (not the current user)
        const isUser1 = row.user1_id === userId;
        const otherUserId = isUser1 ? row.user2_id : row.user1_id;
        const otherUserName = isUser1 ? row.user2_name : row.user1_name;
        const otherUserFirstname = isUser1 ? row.user2_firstname : row.user1_firstname;
        
        return {
          ...row,
          other_user_id: otherUserId,
          other_user_name: otherUserName,
          other_user_firstname: otherUserFirstname,
          car_photos: row.car_photo || null
        };
      });
    } catch (error) {
      console.error('Error fetching user conversations:', error);
      throw error;
    }
  }
  
  // Update last message and activity
  static async updateLastMessage(conversationId, messageId) {
    try {
      await pool.execute(
        `UPDATE conversations 
         SET last_message_id = ?, last_activity = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [messageId, conversationId]
      );
      
      return true;
    } catch (error) {
      console.error('Error updating last message:', error);
      throw error;
    }
  }
  
  // Delete conversation
  static async delete(conversationId) {
    try {
      const [result] = await pool.execute(
        'DELETE FROM conversations WHERE id = ?',
        [conversationId]
      );
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error deleting conversation:', error);
      throw error;
    }
  }
}

module.exports = Conversation; 