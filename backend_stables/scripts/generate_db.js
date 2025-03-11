const db = require('../db');
const bcrypt = require('bcrypt');
require('dotenv').config();

async function createUsersTable() {
  const createTableQuery = `
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      parking_zone INTEGER
    );
  `;
  try {
    await db.query(createTableQuery);
    console.log('Users table created (if it did not exist).');
  } catch (err) {
    console.error('Error creating users table:', err.message);
    process.exit(1);
  }
}

async function insertTestUsers() {
  const testUsers = [
    { email: 'student.01@utrgv.edu', password: 'stables123', parking_zone: 1 },
    { email: 'student.02@utrgv.edu', password: 'stables123', parking_zone: 2 },
    { email: 'student.03@utrgv.edu', password: 'stables123', parking_zone: 3 }
  ];

  for (const user of testUsers) {
    try {
      const hash = await bcrypt.hash(user.password, 10);
      const insertQuery = `
        INSERT INTO users (email, password, parking_zone)
        VALUES ($1, $2, $3)
        ON CONFLICT (email) DO NOTHING;
      `;
      await db.query(insertQuery, [user.email, hash, user.parking_zone]);
      console.log(`User ${user.email} inserted (or already exists).`);
    } catch (err) {
      console.error(`Error inserting user ${user.email}:`, err.message);
    }
  }
}

async function migrate() {
  await createUsersTable();
  await insertTestUsers();
  console.log('Migration complete.');
  process.exit();
}

migrate();
