const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');


const dataDir = path.join(__dirname, '../data');
const dbPath = path.join(dataDir, 'users.db');

if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
    console.log(`Created directory: ${dataDir}`);
  }

const userDb = new sqlite3.Database(dbPath, (err) => {
    if (err) {
      console.error('Error connecting to users database:', err.message);
    } else {
      console.log('Connected to the users database.');
    }
  });
  
  userDb.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE,
    password TEXT,
    parking_zone INTEGER
  )`);
  
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
