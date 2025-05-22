const express = require('express');
const cors = require('cors');
const path = require('path');
const http = require('http');
const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const { testConnection } = require('./config/db');
const authRoutes = require('./routes/auth');
const carRoutes = require('./routes/cars');
const uploadRoutes = require('./routes/upload');
const userRoutes = require('./routes/users');
const messageRoutes = require('./routes/messages');
const notificationRoutes = require('./routes/notifications');
const favoriteRoutes = require('./routes/favorites');
require('dotenv').config();

// Create Express app
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Socket.io connection handler
const connectedUsers = new Map();

io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) {
    return next(new Error('Authentication error'));
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.user = decoded;
    next();
  } catch (err) {
    next(new Error('Authentication error'));
  }
});

io.on('connection', (socket) => {
  const userId = socket.user.id;
  console.log(`User connected: ${userId}`);
  
  // Store the socket connection with user ID
  connectedUsers.set(userId, socket.id);
  
  // Handle disconnect
  socket.on('disconnect', () => {
    console.log(`User disconnected: ${userId}`);
    connectedUsers.delete(userId);
  });
  
  // Listen for new message
  socket.on('send_message', (data) => {
    const receiverId = data.receiver_id;
    const receiverSocketId = connectedUsers.get(receiverId.toString());
    
    // If receiver is online, send them the message in real-time
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('receive_message', {
        message: data.message,
        senderId: userId,
        senderName: data.senderName,
        carId: data.carId,
        conversationId: data.conversationId,
        createdAt: data.createdAt
      });
    }
  });
  
  // Listen for typing events
  socket.on('typing', (data) => {
    const receiverId = data.receiver_id;
    const receiverSocketId = connectedUsers.get(receiverId.toString());
    
    // If receiver is online, notify them that user is typing
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('typing', {
        senderId: userId,
        conversationId: data.conversationId,
        isTyping: data.isTyping
      });
    }
  });
});

// Export the io instance to be used in other modules
app.set('io', io);
app.set('connectedUsers', connectedUsers);

// Configure CORS
app.use(cors());

// Middleware
app.use(express.json());

// Serve static files from uploads folder
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/cars', carRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/users', userRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/favorites', favoriteRoutes);

// Home route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Sayarti API' });
});

// Database setup script
async function setupDatabase() {
  const { pool } = require('./config/db');
  
  try {
    // Create users table if it doesn't exist
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        firstname VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        numerotlf VARCHAR(20) NOT NULL,
        motdepasse VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

    // Create cars table if it doesn't exist
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS cars (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        brand VARCHAR(100) NOT NULL,
        location VARCHAR(100) NOT NULL,
        add_date DATE NOT NULL,
        added_by_id INT NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        description TEXT,
        puissance_fiscale INT NOT NULL,
        carburant VARCHAR(50) NOT NULL,
        date_mise_en_circulation DATE NOT NULL,
        \`condition\` VARCHAR(50) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (added_by_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    // Create car_photos table if it doesn't exist
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS car_photos (
        id INT AUTO_INCREMENT PRIMARY KEY,
        car_id INT NOT NULL,
        photo_url VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE
      )
    `);
    
    // Create messages table if it doesn't exist
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS messages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        sender_id INT NOT NULL,
        receiver_id INT NOT NULL,
        car_id INT NOT NULL,
        message TEXT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE
      )
    `);
    
    // Create notifications table if it doesn't exist
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        type VARCHAR(50) NOT NULL,
        target_id INT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    
    // Create favorites table if it doesn't exist
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS favorites (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        car_id INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
        UNIQUE KEY unique_favorite (user_id, car_id)
      )
    `);
    
    // Add indexes for better performance
    await pool.execute(`CREATE INDEX IF NOT EXISTS idx_notification_user_id ON notifications(user_id)`);
    await pool.execute(`CREATE INDEX IF NOT EXISTS idx_notification_is_read ON notifications(is_read)`);
    await pool.execute(`CREATE INDEX IF NOT EXISTS idx_notification_created_at ON notifications(created_at)`);
    await pool.execute(`CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id)`);
    
    console.log('Database tables initialized successfully');
  } catch (error) {
    console.error('Error setting up database:', error);
    process.exit(1);
  }
}

// Start server
const PORT = process.env.PORT || 5000;
async function startServer() {
  // Test DB connection
  const isConnected = await testConnection();
  if (!isConnected) {
    console.error('Unable to connect to database. Make sure your MySQL server is running.');
    process.exit(1);
  }
  
  // Setup database tables
  await setupDatabase();
  
  // Start listening
  server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

startServer(); 