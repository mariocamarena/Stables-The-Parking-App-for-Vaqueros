const express = require('express');
const app = express();
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('');


app.get('/', (req, res) => {
  res.send('Stables API running...');
});

//start server

app.get('/parking',(req,res) => {
  res.json({
    lot_id: 'LOT_E16',
    zone_type: 'zone_2',
    total_spots: 5,
    available_spots: 2,
    updated_at: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));