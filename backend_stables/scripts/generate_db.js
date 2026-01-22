// =============================================================================
// ORIGINAL POSTGRESQL MIGRATION CODE (commented out)
// Reason: PostgreSQL database is no longer active/available for the deployed demo.
// Using in-memory storage instead for simplicity - no external database required.
// =============================================================================

// const db = require('../db');
// const bcrypt = require('bcrypt');
// require('dotenv').config();

// async function createUsersTable() {
//   const createTableQuery = `
//     CREATE TABLE IF NOT EXISTS users (
//       id SERIAL PRIMARY KEY,
//       email TEXT UNIQUE NOT NULL,
//       password TEXT NOT NULL,
//       role TEXT DEFAULT 'user',
//       parking_zone INTEGER
//     );
//   `;
//   try {
//     await db.query(createTableQuery);
//     console.log('Users table created (if it did not exist).');
//   } catch (err) {
//     console.error('Error creating users table:', err.message);
//     throw err;
//   }
// }

// async function insertTestUsers() {
//   const testUsers = [
//     { email: 'student.01@utrgv.edu', password: 'stables123', role: 'user', parking_zone: 1 },
//     { email: 'student.02@utrgv.edu', password: 'stables123', role: 'user', parking_zone: 2 },
//     { email: 'student.03@utrgv.edu', password: 'stables123', role: 'user', parking_zone: 3 },
//     { email: 'admin@utrgv.edu', password: 'admin123', role: 'admin', parking_zone: 0 },
//   ];

//   for (const user of testUsers) {
//     try {
//       const hash = await bcrypt.hash(user.password, 10);
//       const insertQuery = `
//         INSERT INTO users (email, password, role, parking_zone)
//         VALUES ($1, $2, $3, $4)
//         ON CONFLICT (email) DO NOTHING;
//       `;
//       await db.query(insertQuery, [user.email, hash, user.role, user.parking_zone]);
//       console.log(`User ${user.email} inserted (or already exists).`);
//     } catch (err) {
//       console.error(`Error inserting user ${user.email}:`, err.message);
//     }
//   }
// }

// async function runMigrations() {
//   try {
//     await createUsersTable();
//     await insertTestUsers();
//     console.log('Migration complete.');
//   } catch (err) {
//     console.error('Migration failed:', err.message);
//     throw err;
//   }
// }

// =============================================================================
// NEW IN-MEMORY IMPLEMENTATION FOR DEMO
// No-op migrations - users are pre-defined in db.js
// =============================================================================

async function runMigrations() {
  console.log('Using in-memory user store - no migrations needed.');
  console.log('Demo users available:');
  console.log('  - student.01@utrgv.edu / stables123 (zone 1)');
  console.log('  - student.02@utrgv.edu / stables123 (zone 2)');
  console.log('  - student.03@utrgv.edu / stables123 (zone 3)');
  console.log('  - admin@utrgv.edu / admin123 (admin)');
}

module.exports = { runMigrations };
