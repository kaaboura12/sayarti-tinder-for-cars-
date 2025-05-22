const express = require('express');
const router = express.Router();
const User = require('../models/User');
const authMiddleware = require('../middleware/auth');

// Get user profile by ID - only returns non-sensitive information
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Return only safe fields (no password)
    res.json({
      id: user.id,
      name: user.name,
      firstname: user.firstname,
      email: user.email,
      numerotlf: user.numerotlf
    });
  } catch (error) {
    console.error(`Error in GET /users/${req.params.id}:`, error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Current user profile
router.get('/me/profile', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Return only safe fields (no password)
    res.json({
      id: user.id,
      name: user.name,
      firstname: user.firstname,
      email: user.email,
      numerotlf: user.numerotlf
    });
  } catch (error) {
    console.error('Error in GET /users/me/profile:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router; 