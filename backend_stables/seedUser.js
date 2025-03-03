// seedUser.js
const db = require('./database');
const bcrypt = require('bcryptjs');

// Mock credentials and zone assignment
const email = 'oziel.sauceda01@utrgv.edu';
const plainPassword = 'Stables123';
const zone = 2; // The user bought a zone 2 pass

const saltRounds = 10;

// Hash the password and insert the user with their assigned zone.
bcrypt.hash(plainPassword, saltRounds, (err, hash) => {
  if (err) {
    return console.error('Error hashing password:', err);
  }

  const sql = `INSERT INTO users (email, password_hash, zone) VALUES (?, ?, ?)`;

  db.run(sql, [email, hash, zone], function (error) {
    if (error) {
      // This may fail if the user already exists due to the UNIQUE constraint on email.
      return console.error('Error inserting user:', error.message);
    }
    console.log('Mock user inserted with ID:', this.lastID);
  });
});
