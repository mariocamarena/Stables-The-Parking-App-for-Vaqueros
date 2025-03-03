// database.js
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Create or open the SQLite database file.
const dbPath = path.join(__dirname, 'myDatabase.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Could not connect to database:', err.message);
  } else {
    console.log('Connected to the SQLite database.');
  }
});

// Create a 'users' table if it doesn't exist.
// The table now includes a 'zone' column to store the parking zone (1, 2, or 3).
db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      zone INTEGER NOT NULL
    )
  `);
});

module.exports = db;
