const express = require('express');
const app = express();
const sqlite3 = require('sqlite3').verbose();
const {spawn} = require('child_process');
const fs = require('fs');
const path = require('path');

const db = new sqlite3.Database('');


app.get('/', (req, res) => {
  res.send('Stables API running...');
});

//start server

const dataPath = path.join(__dirname, 'data/simulated_data.json');

function updateSimulatedData(){
  const pythonProcess = spawn('python', ['scripts/sensor_data.py']);
  
  pythonProcess.on('close', (code) => {
    console.log("=== Generated Data ===");
  });
}

updateSimulatedData();
setInterval(updateSimulatedData, 1000);


app.get('/parking',(req,res) => {
  // res.json({
  //   lot_id: 'LOT_E16',
  //   zone_type: 'zone_2',
  //   total_spots: 5,
  //   available_spots: 2,
  //   updated_at: new Date().toISOString()
  // });

  const data = fs.readFileSync(dataPath, 'utf8');
  const parsedData = JSON.parse(data);
  res.json(parsedData);
});

app.get('/dashboard', (req,res) => {
  res.sendFile(path.join(__dirname, 'scripts', 'dashboard.html'));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));