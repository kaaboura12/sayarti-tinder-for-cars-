const { pool } = require('../config/db');
const bcrypt = require('bcrypt');

class User {
  // Create a new user
  static async create(userData) {
    const { name, firstname, email, numerotlf, motdepasse } = userData;
    
    // Hash password
    const hashedPassword = await bcrypt.hash(motdepasse, 10);
    
    try {
      const [result] = await pool.execute(
        'INSERT INTO users (name, firstname, email, numerotlf, motdepasse) VALUES (?, ?, ?, ?, ?)',
        [name, firstname, email, numerotlf, hashedPassword]
      );
      
      return { id: result.insertId, name, firstname, email, numerotlf };
    } catch (error) {
      throw error;
    }
  }
  
  // Find user by email
  static async findByEmail(email) {
    try {
      const [rows] = await pool.execute(
        'SELECT * FROM users WHERE email = ?',
        [email]
      );
      return rows[0];
    } catch (error) {
      throw error;
    }
  }
  
  // Find user by ID
  static async findById(id) {
    try {
      const [rows] = await pool.execute(
        'SELECT id, name, firstname, email, numerotlf FROM users WHERE id = ?',
        [id]
      );
      return rows[0];
    } catch (error) {
      throw error;
    }
  }
  
  // Verify password
  static async verifyPassword(password, hashedPassword) {
    return await bcrypt.compare(password, hashedPassword);
  }
}

module.exports = User; 