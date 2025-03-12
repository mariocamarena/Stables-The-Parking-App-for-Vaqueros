
// const { Pool } = require('pg');

// const pool = new Pool({
//   connectionString: process.env.DATABASE_URL || 'postgres://postgres:0000@127.0.0.1:5432/users_01',
// });

// module.exports = {
//   query: (text, params) => pool.query(text, params),
// };

// console.log("doneeeeeeeeeeeeeeeee")

const { Pool } = require('pg');
require('dotenv').config();

const connectionString = process.env.DATABASE_URL || 'postgres://postgres:0000@127.0.0.1:5432/users_01';
const ssl = connectionString.includes('127.0.0.1') ? false : { rejectUnauthorized: false };


const pool = new Pool({
  connectionString,
  ssl,
});

module.exports = {
  query: (text, params) => pool.query(text, params),
};

console.log("doneeeeeeeeeeeeeeeee")