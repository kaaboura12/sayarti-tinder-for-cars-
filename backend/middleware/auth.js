const jwt = require('jsonwebtoken');
require('dotenv').config();

// Middleware to check if request includes a valid JWT token
module.exports = function(req, res, next) {
  // Get token from header
  const authHeader = req.header('Authorization');
  
  if (!authHeader) {
    return res.status(401).json({ message: 'No token, authorization denied' });
  }
  
  // Check if auth header has Bearer prefix
  const parts = authHeader.split(' ');
  let token;
  
  if (parts.length === 2 && parts[0] === 'Bearer') {
    token = parts[1];
  } else {
    token = authHeader;
  }
  
  try {
    // Verify token and extract payload
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'sayarti_secret_key');
    
    // Add user info to request object - fixed to match the token structure
    req.user = {
      id: decoded.id,
      email: decoded.email
    };
    next();
  } catch (err) {
    res.status(401).json({ message: 'Token is not valid' });
  }
}; 