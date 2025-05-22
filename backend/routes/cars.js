const express = require('express');
const router = express.Router();
const Car = require('../models/Car');
const authMiddleware = require('../middleware/auth');

// Get all cars with optional filters
router.get('/', authMiddleware, async (req, res) => {
  try {
    // Extract filter params from query
    const filters = {
      brand: req.query.brand,
      minPrice: req.query.minPrice ? parseFloat(req.query.minPrice) : null,
      maxPrice: req.query.maxPrice ? parseFloat(req.query.maxPrice) : null,
      condition: req.query.condition,
      carburant: req.query.carburant,
      search: req.query.search,
    };
    
    // Remove null/undefined filters
    Object.keys(filters).forEach(key => 
      (filters[key] == null) && delete filters[key]
    );
    
    const cars = await Car.getAll(filters);
    res.json(cars);
  } catch (error) {
    console.error('Error in GET /cars:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get car by ID
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const car = await Car.getById(req.params.id);
    
    if (!car) {
      return res.status(404).json({ message: 'Car not found' });
    }
    
    res.json(car);
  } catch (error) {
    console.error(`Error in GET /cars/${req.params.id}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Create a new car
router.post('/', authMiddleware, async (req, res) => {
  try {
    // Extract car data from request body
    const {
      title,
      brand,
      location,
      add_date,
      price,
      description,
      puissance_fiscale,
      carburant,
      date_mise_en_circulation,
      condition,
      photos
    } = req.body;
    
    // Validate required fields
    if (!title || !brand || !price) {
      return res.status(400).json({ message: 'Title, brand, and price are required' });
    }
    
    // Create car with the user ID from auth token
    const carData = {
      title,
      brand,
      location,
      addDate: add_date,
      addedBy: req.user.id,
      price,
      description,
      puissanceFiscale: puissance_fiscale,
      carburant,
      dateMiseEnCirculation: date_mise_en_circulation,
      condition
    };
    
    const newCar = await Car.create(carData, photos || []);
    res.status(201).json(newCar);
  } catch (error) {
    console.error('Error in POST /cars:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update a car
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    // Check if car exists
    const car = await Car.getById(req.params.id);
    
    if (!car) {
      return res.status(404).json({ message: 'Car not found' });
    }
    
    // Verify user owns this car
    if (car.added_by_id !== req.user.id) {
      return res.status(403).json({ message: 'You can only update your own cars' });
    }
    
    // Extract car data from request body
    const {
      title,
      brand,
      location,
      price,
      description,
      puissance_fiscale,
      carburant,
      date_mise_en_circulation,
      condition,
      photos
    } = req.body;
    
    // Update car
    const carData = {
      title,
      brand,
      location,
      price,
      description,
      puissanceFiscale: puissance_fiscale,
      carburant,
      dateMiseEnCirculation: date_mise_en_circulation,
      condition
    };
    
    const updatedCar = await Car.update(req.params.id, carData, photos);
    res.json(updatedCar);
  } catch (error) {
    console.error(`Error in PUT /cars/${req.params.id}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Delete a car
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    // Check if car exists
    const car = await Car.getById(req.params.id);
    
    if (!car) {
      return res.status(404).json({ message: 'Car not found' });
    }
    
    // Verify user owns this car
    if (car.added_by_id !== req.user.id) {
      return res.status(403).json({ message: 'You can only delete your own cars' });
    }
    
    // Delete car
    const deleted = await Car.delete(req.params.id);
    
    if (deleted) {
      res.json({ message: 'Car deleted successfully' });
    } else {
      res.status(500).json({ message: 'Failed to delete car' });
    }
  } catch (error) {
    console.error(`Error in DELETE /cars/${req.params.id}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get cars by authenticated user
router.get('/user/me', authMiddleware, async (req, res) => {
  try {
    const cars = await Car.getByUserId(req.user.id);
    res.json(cars);
  } catch (error) {
    console.error('Error in GET /cars/user/me:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router; 