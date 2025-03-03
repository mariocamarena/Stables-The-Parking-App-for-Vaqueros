// index.js
const db = require('./database');
const bcrypt = require('bcryptjs');

// A function to authenticate a user by email and password.
// If the credentials match, the function resolves with the user record (including the 'zone').
// Otherwise, it resolves with false.
function authenticateUser(email, plainPassword) {
  return new Promise((resolve, reject) => {
    const selectSql = `SELECT * FROM users WHERE email = ?`;
    db.get(selectSql, [email], (err, row) => {
      if (err) return reject(err);

      // If user is not found, return false.
      if (!row) {
        return resolve(false);
      }

      // Compare the provided password with the stored hash.
      bcrypt.compare(plainPassword, row.password_hash, (compareErr, isMatch) => {
        if (compareErr) return reject(compareErr);

        // If credentials match, resolve with the full user row.
        if (isMatch) {
          resolve(row);
        } else {
          resolve(false);
        }
      });
    });
  });
}

// Testing the authentication function.
(async () => {
  // Attempt to log in with the correct credentials.
  const user = await authenticateUser('oziel.sauceda01@utrgv.edu', 'Stables123');

  if (user) {
    console.log('Login success! User zone:', user.zone);
    // At this point, you can restrict the parking view based on user.zone.
    // For example:
    if (user.zone === 2) {
      console.log('Display parking area for Zone 2 only.');
      // Load data or render UI components specific to Zone 2.
    } else {
      console.log('User does not have access to Zone 2 parking.');
    }
  } else {
    console.log('Login failed! Invalid credentials.');
  }
})();
