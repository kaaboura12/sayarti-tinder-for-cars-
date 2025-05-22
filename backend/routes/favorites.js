const express = require('express');
const router = express.Router();
const Favorite = require('../models/Favorite');
const Car = require('../models/Car');
const authMiddleware = require('../middleware/auth');

// Get all favorite cars for the current user
router.get('/', authMiddleware, async (req, res) => {
  try {
    const favorites = await Favorite.getFavoritesByUserId(req.user.id);
    res.json(favorites);
  } catch (error) {
    console.error('Error in GET /favorites:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Add a car to favorites
router.post('/:carId', authMiddleware, async (req, res) => {
  try {
    const { carId } = req.params;
    
    // Check if car exists
    const car = await Car.getById(carId);
    if (!car) {
      return res.status(404).json({ message: 'Car not found' });
    }
    
    const result = await Favorite.addFavorite(req.user.id, carId);
    
    if (result.already_exists) {
      return res.status(200).json({ message: 'Car already in favorites', id: result.id });
    }
    
    res.status(201).json({ message: 'Car added to favorites', id: result.id });
  } catch (error) {
    console.error(`Error in POST /favorites/${req.params.carId}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Remove a car from favorites
router.delete('/:carId', authMiddleware, async (req, res) => {
  try {
    const { carId } = req.params;
    const removed = await Favorite.removeFavorite(req.user.id, carId);
    
    if (removed) {
      res.json({ message: 'Car removed from favorites' });
    } else {
      res.status(404).json({ message: 'Car not found in favorites' });
    }
  } catch (error) {
    console.error(`Error in DELETE /favorites/${req.params.carId}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Check if a car is favorited by the current user
router.get('/check/:carId', authMiddleware, async (req, res) => {
  try {
    const { carId } = req.params;
    const isFavorited = await Favorite.isFavorited(req.user.id, carId);
    
    res.json({ is_favorited: isFavorited });
  } catch (error) {
    console.error(`Error in GET /favorites/check/${req.params.carId}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router; 