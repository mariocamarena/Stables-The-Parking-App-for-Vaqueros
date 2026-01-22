// =============================================================================
// ORIGINAL POSTGRESQL CODE (commented out)
// Reason: PostgreSQL database is no longer active/available for the deployed demo.
// Using in-memory storage instead for simplicity - no external database required.
// =============================================================================

// const { Pool } = require('pg');
// require('dotenv').config();

// const connectionString = process.env.DATABASE_URL || 'postgres://postgres:0000@127.0.0.1:5432/users_01';
// const ssl = connectionString.includes('127.0.0.1') ? false : { rejectUnauthorized: false };

// const pool = new Pool({
//   connectionString,
//   ssl,
// });

// module.exports = {
//   query: (text, params) => pool.query(text, params),
// };

// console.log("doneeeeeeeeeeeeeeeee")

// =============================================================================
// NEW IN-MEMORY IMPLEMENTATION FOR DEMO
// Simple in-memory user store - no database required, users reset on server restart
// =============================================================================

const users = [
  { id: 1, email: 'student.01@utrgv.edu', password: 'stables123', role: 'user', parking_zone: 1 },
  { id: 2, email: 'student.02@utrgv.edu', password: 'stables123', role: 'user', parking_zone: 2 },
  { id: 3, email: 'student.03@utrgv.edu', password: 'stables123', role: 'user', parking_zone: 3 },
  { id: 4, email: 'admin@utrgv.edu', password: 'admin123', role: 'admin', parking_zone: 0 },
];

let nextId = 5;

// Simulates PostgreSQL query interface for compatibility
module.exports = {
  query: async (text, params) => {
    // SELECT user by email
    if (text.includes('SELECT') && text.includes('FROM users') && text.includes('email')) {
      const email = params[0];
      const user = users.find(u => u.email === email);
      return { rows: user ? [user] : [] };
    }

    // SELECT all users
    if (text.includes('SELECT') && text.includes('FROM users') && !text.includes('WHERE')) {
      return { rows: users.map(u => ({ id: u.id, email: u.email, role: u.role, parking_zone: u.parking_zone })) };
    }

    // INSERT new user
    if (text.includes('INSERT INTO users')) {
      const [email, password, parking_zone] = params;
      const newUser = { id: nextId++, email, password, role: 'user', parking_zone };
      users.push(newUser);
      return { rows: [newUser] };
    }

    // UPDATE password
    if (text.includes('UPDATE users SET password')) {
      const [password, email] = params;
      const user = users.find(u => u.email === email);
      if (user) user.password = password;
      return { rows: [] };
    }

    // DELETE user
    if (text.includes('DELETE FROM users')) {
      const id = parseInt(params[0]);
      const index = users.findIndex(u => u.id === id);
      if (index !== -1) users.splice(index, 1);
      return { rows: [] };
    }

    // CREATE TABLE - no-op for in-memory
    if (text.includes('CREATE TABLE')) {
      return { rows: [] };
    }

    return { rows: [] };
  },

  // Expose users for debugging if needed
  getUsers: () => users
};

console.log("In-memory user store initialized with demo users");
