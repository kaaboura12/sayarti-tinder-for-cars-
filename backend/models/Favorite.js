const { pool } = require('../config/db');

class Favorite {
  // Add a car to favorites
  static async addFavorite(userId, carId) {
    try {
      // Check if already favorited
      const [existingRows] = await pool.execute(
        'SELECT * FROM favorites WHERE user_id = ? AND car_id = ?',
        [userId, carId]
      );
      
      if (existingRows.length > 0) {
        return { already_exists: true, id: existingRows[0].id };
      }
      
      // Create new favorite
      const [result] = await pool.execute(
        'INSERT INTO favorites (user_id, car_id, created_at) VALUES (?, ?, NOW())',
        [userId, carId]
      );
      
      return { id: result.insertId, user_id: userId, car_id: carId };
    } catch (error) {
      console.error('Error adding favorite:', error);
      throw error;
    }
  }
  
  // Remove a car from favorites
  static async removeFavorite(userId, carId) {
    try {
      const [result] = await pool.execute(
        'DELETE FROM favorites WHERE user_id = ? AND car_id = ?',
        [userId, carId]
      );
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error removing favorite:', error);
      throw error;
    }
  }
  
  // Get all favorite cars for a user
  static async getFavoritesByUserId(userId) {
    try {
      const [rows] = await pool.execute(
        `SELECT f.*, c.*, GROUP_CONCAT(cp.photo_url) AS photos
         FROM favorites f
         JOIN cars c ON f.car_id = c.id
         LEFT JOIN car_photos cp ON c.id = cp.car_id
         WHERE f.user_id = ?
         GROUP BY c.id
         ORDER BY f.created_at DESC`,
        [userId]
      );
      
      // Format the results to convert the comma-separated photos to an array
      return rows.map(car => {
        return {
          ...car,
          photos: car.photos ? car.photos.split(',') : []
        };
      });
    } catch (error) {
      console.error('Error fetching favorites:', error);
      throw error;
    }
  }
  
  // Check if a car is favorited by a user
  static async isFavorited(userId, carId) {
    try {
      const [rows] = await pool.execute(
        'SELECT * FROM favorites WHERE user_id = ? AND car_id = ?',
        [userId, carId]
      );
      
      return rows.length > 0;
    } catch (error) {
      console.error('Error checking favorite status:', error);
      throw error;
    }
  }
}

module.exports = Favorite; 