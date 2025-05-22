const { pool } = require('../config/db');

class Car {
  // Get all cars with optional filters
  static async getAll(filters = {}) {
    try {
      let query = `
        SELECT c.*, GROUP_CONCAT(cp.photo_url) AS photos
        FROM cars c
        LEFT JOIN car_photos cp ON c.id = cp.car_id
      `;
      
      const conditions = [];
      const params = [];
      
      // Add filter conditions if any
      if (filters.brand) {
        conditions.push('c.brand LIKE ?');
        params.push(`%${filters.brand}%`);
      }
      
      if (filters.minPrice) {
        conditions.push('c.price >= ?');
        params.push(filters.minPrice);
      }
      
      if (filters.maxPrice) {
        conditions.push('c.price <= ?');
        params.push(filters.maxPrice);
      }
      
      if (filters.condition) {
        conditions.push('c.condition = ?');
        params.push(filters.condition);
      }
      
      if (filters.carburant) {
        conditions.push('c.carburant = ?');
        params.push(filters.carburant);
      }
      
      // Add search by title filter
      if (filters.search) {
        conditions.push('c.title LIKE ?');
        params.push(`%${filters.search}%`);
      }
      
      if (conditions.length > 0) {
        query += ' WHERE ' + conditions.join(' AND ');
      }
      
      query += ' GROUP BY c.id ORDER BY c.id DESC';
      
      const [rows] = await pool.execute(query, params);
      
      // Format the results to convert the comma-separated photos to an array
      return rows.map(car => {
        return {
          ...car,
          photos: car.photos ? car.photos.split(',') : []
        };
      });
    } catch (error) {
      console.error('Error fetching cars:', error);
      throw error;
    }
  }
  
  // Get car by ID
  static async getById(id) {
    try {
      const [rows] = await pool.execute(
        `SELECT c.*, GROUP_CONCAT(cp.photo_url) AS photos
         FROM cars c
         LEFT JOIN car_photos cp ON c.id = cp.car_id
         WHERE c.id = ?
         GROUP BY c.id`,
        [id]
      );
      
      if (rows.length === 0) {
        return null;
      }
      
      const car = rows[0];
      return {
        ...car,
        photos: car.photos ? car.photos.split(',') : []
      };
    } catch (error) {
      console.error('Error fetching car by ID:', error);
      throw error;
    }
  }
  
  // Create a new car
  static async create(carData, photoUrls) {
    const connection = await pool.getConnection();
    
    try {
      await connection.beginTransaction();
      
      // Modify the SQL columns based on what's available in the database
      let query = `INSERT INTO cars (
        title, brand, location, add_date, price, description,
        puissance_fiscale, carburant, date_mise_en_circulation, \`condition\`
      `;
      
      // Only include added_by_id if it has a value
      if (carData.addedBy) {
        query += `, added_by_id`;
      }
      
      query += `) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?`;
      
      // Only include the added_by_id parameter if it has a value
      if (carData.addedBy) {
        query += `, ?`;
      }
      
      query += `)`;
      
      // Build the parameters array
      const params = [
        carData.title,
        carData.brand,
        carData.location,
        carData.addDate,
        carData.price,
        carData.description,
        carData.puissanceFiscale,
        carData.carburant,
        carData.dateMiseEnCirculation,
        carData.condition
      ];
      
      // Only add the addedBy parameter if it has a value
      if (carData.addedBy) {
        params.push(carData.addedBy);
      }
      
      // Execute the SQL
      const [result] = await connection.execute(query, params);
      
      const carId = result.insertId;
      
      // Insert photos if any
      if (photoUrls && photoUrls.length > 0) {
        const photoValues = photoUrls.map(url => [carId, url]);
        
        await connection.query(
          'INSERT INTO car_photos (car_id, photo_url) VALUES ?',
          [photoValues]
        );
      }
      
      await connection.commit();
      
      // Return the created car with photos
      return await Car.getById(carId);
    } catch (error) {
      await connection.rollback();
      console.error('Error creating car:', error);
      throw error;
    } finally {
      connection.release();
    }
  }
  
  // Update a car
  static async update(id, carData, photoUrls) {
    const connection = await pool.getConnection();
    
    try {
      await connection.beginTransaction();
      
      // Update car data
      await connection.execute(
        `UPDATE cars SET
          title = ?,
          brand = ?,
          location = ?,
          price = ?,
          description = ?,
          puissance_fiscale = ?,
          carburant = ?,
          date_mise_en_circulation = ?,
          \`condition\` = ?
        WHERE id = ?`,
        [
          carData.title,
          carData.brand,
          carData.location,
          carData.price,
          carData.description,
          carData.puissanceFiscale,
          carData.carburant,
          carData.dateMiseEnCirculation,
          carData.condition,
          id
        ]
      );
      
      // Update photos if provided
      if (photoUrls) {
        // Delete existing photos
        await connection.execute('DELETE FROM car_photos WHERE car_id = ?', [id]);
        
        // Insert new photos
        if (photoUrls.length > 0) {
          const photoValues = photoUrls.map(url => [id, url]);
          
          await connection.query(
            'INSERT INTO car_photos (car_id, photo_url) VALUES ?',
            [photoValues]
          );
        }
      }
      
      await connection.commit();
      
      // Return the updated car
      return await Car.getById(id);
    } catch (error) {
      await connection.rollback();
      console.error('Error updating car:', error);
      throw error;
    } finally {
      connection.release();
    }
  }
  
  // Delete a car
  static async delete(id) {
    const connection = await pool.getConnection();
    
    try {
      await connection.beginTransaction();
      
      // Delete photos first (due to foreign key constraint)
      await connection.execute('DELETE FROM car_photos WHERE car_id = ?', [id]);
      
      // Delete the car
      const [result] = await connection.execute('DELETE FROM cars WHERE id = ?', [id]);
      
      await connection.commit();
      
      return result.affectedRows > 0;
    } catch (error) {
      await connection.rollback();
      console.error('Error deleting car:', error);
      throw error;
    } finally {
      connection.release();
    }
  }
  
  // Get cars by user ID
  static async getByUserId(userId) {
    try {
      // Changed to use id for ordering instead of created_at
      const [rows] = await pool.execute(
        `SELECT c.*, GROUP_CONCAT(cp.photo_url) AS photos
         FROM cars c
         LEFT JOIN car_photos cp ON c.id = cp.car_id
         WHERE c.added_by_id = ?
         GROUP BY c.id
         ORDER BY c.id DESC`,
        [userId]
      );
      
      return rows.map(car => {
        return {
          ...car,
          photos: car.photos ? car.photos.split(',') : []
        };
      });
    } catch (error) {
      console.error('Error fetching user cars:', error);
      // If the query fails due to missing column, return empty array
      if (error.code === 'ER_BAD_FIELD_ERROR' && error.message.includes('added_by')) {
        return [];
      }
      throw error;
    }
  }
}

module.exports = Car; 