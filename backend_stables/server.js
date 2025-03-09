const express = require('express');
const app = express();
const sqlite3 = require('sqlite3').verbose();
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
require('dotenv').config();

// 1) Keep your original "sensorDb" for any future usage if needed
//    (Previously 'db = new sqlite3.Database('')'—renamed to avoid confusion with userDb)
const sensorDb = new sqlite3.Database('', (err) => {
  if (err) {
    console.error('Error connecting to sensor DB (in-memory or empty string):', err.message);
  } else {
    console.log('Connected to sensorDb (currently unused).');
  }
});

// 2) CORS setup stays the same
const allowedOrigins = [
  'http://localhost:5500',
  'https://stables-utrgv-parking-app.web.app',
];

app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  }
}));

// Needed to parse JSON bodies (e.g., for login requests)
app.use(express.json());

// Simple root endpoint
app.get('/', (req, res) => {
  res.send('Stables API running...');
});

// =======================
// New: User Authentication Setup
// =======================
const bcrypt = require('bcrypt');

// 3) Create a separate database for user authentication
const userDb = new sqlite3.Database('./users.db', (err) => {
  if (err) {
    console.error('Error connecting to users database:', err.message);
  } else {
    console.log('Connected to the users database.');
  }
});

// Create the 'users' table if it doesn't exist
userDb.run(`CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE,
  password TEXT,
  parking_zone INTEGER
)`);

// Pre-populate the database with test accounts (if not already present)
const testUsers = [
  { email: 'student.01@utrgv.edu', password: 'stables123', parking_zone: 1 },
  { email: 'student.02@utrgv.edu', password: 'stables123', parking_zone: 2 },
  { email: 'student.03@utrgv.edu', password: 'stables123', parking_zone: 3 }
];

testUsers.forEach(user => {
  bcrypt.hash(user.password, 10, (err, hash) => {
    if (err) {
      console.error(`Error hashing password for ${user.email}:`, err.message);
    } else {
      userDb.run(
        'INSERT OR IGNORE INTO users (email, password, parking_zone) VALUES (?, ?, ?)',
        [user.email, hash, user.parking_zone],
        function(err) {
          if (err) {
            console.error(`Error inserting user ${user.email}:`, err.message);
          } else {
            console.log(`User ${user.email} inserted or already exists.`);
          }
        }
      );
    }
  });
});

// Login endpoint: checks provided credentials against the userDb
app.post('/login', (req, res) => {
  const { email, password } = req.body;
  userDb.get('SELECT * FROM users WHERE email = ?', [email], (err, user) => {
    if (err) {
      console.error(err.message);
      return res.status(500).json({ error: 'Internal server error' });
    }
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    bcrypt.compare(password, user.password, (err, result) => {
      if (result) {
        // Login successful – return user details (including parking_zone)
        res.json({ id: user.id, email: user.email, parking_zone: user.parking_zone });
      } else {
        res.status(401).json({ error: 'Invalid email or password' });
      }
    });
  });
});
// =======================
// End of User Authentication Setup
// =======================

// =======================
// Existing functionality: Simulated data update & other endpoints
// =======================
const dataPath = path.join(__dirname, 'data/simulated_data.json');

function updateSimulatedData() {
  const pythonProcess = spawn('python', ['scripts/sensor_data.py']);
  pythonProcess.on('close', (code) => {
    console.log("=== Generated Data ===");
  });
}

// Call once and then periodically
updateSimulatedData();
setInterval(updateSimulatedData, 1000);

app.get('/parking', (req, res) => {
  try {
    const data = fs.readFileSync(dataPath, 'utf8');
    const parsedData = JSON.parse(data);
    res.json(parsedData);
  } catch (error) {
    console.error('Error reading or parsing simulated_data.json:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'scripts', 'dashboard.html'));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
