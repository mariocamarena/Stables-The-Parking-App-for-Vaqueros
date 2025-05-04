const express = require('express');
const app = express();
const sqlite3 = require('sqlite3').verbose();
const {spawn} = require('child_process');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const bcrypt = require('bcrypt');
const db = require('./db');
require('dotenv').config();
const claimedSpots = new Map();

// const frontendUrl = 'https://stables-utrgv-parking-app.web.app';
// const frontendUrl = 'https://stables-utrgv-parking-app.web.app' && 'http://localhost:5500';
// app.use(cors({ origin: frontendUrl }));

const { runMigrations } = require('./scripts/generate_db');


const allowedOrigins = [
  'http://localhost:5500',
  'https://stables-utrgv-parking-app.web.app',
  'https://stables-the-parking-app-for-vaqueros.onrender.com'  
];

app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  }
}));

app.use(express.json());


const dbPath = process.env.SQLITE_DB_PATH || './data/users.db';
const userDb = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error connecting to users database:', err.message);
  } else {
    console.log('Connected to the users database.');
  }
});


app.post('/login', async (req, res) => {
  console.log("IN / login");
  const { email, password } = req.body;
  try {
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = result.rows[0];
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (passwordMatch) {
      res.json({ id: user.id, email: user.email, parking_zone: user.parking_zone });
    } else {
      res.status(401).json({ error: 'Invalid email or password' });
    }
  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});


app.post('/change-password', async (req, res) => {
  const { email, oldPassword, newPassword } = req.body;
  try {
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = result.rows[0];
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Old password is incorrect' });
    }
    const newHash = await bcrypt.hash(newPassword, 10);
    await db.query('UPDATE users SET password = $1 WHERE email = $2', [newHash, email]);
    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    console.error('Change password error:', err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/parking/claim', (req, res) => {
  const { spot_id, user_id } = req.body;
  if (!spot_id || !user_id) {
    return res.status(400).json({ error: 'Missing spot_id or user_id' });
  }
  const existing = claimedSpots.get(spot_id);
  if (existing && existing !== user_id) {
    return res.status(409).json({ error: 'Spot already taken' });
  }
  claimedSpots.set(spot_id, user_id);
  res.json({ success: true, spot_id });
});

app.post('/parking/unclaim', (req, res) => {
  const { spot_id, user_id } = req.body;
  if (!spot_id || !user_id) {
    return res.status(400).json({ error: 'Missing spot_id or user_id' });
  }
  const existing = claimedSpots.get(spot_id);
  if (existing !== user_id) {

    return res.status(403).json({ error: 'Cannot unclaim this spot' });
  }
  claimedSpots.delete(spot_id);
  res.json({ success: true, spot_id });
});



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


// app.get('/parking',(req,res) => {
//   // res.json({
//   //   lot_id: 'LOT_E16',
//   //   zone_type: 'zone_2',
//   //   total_spots: 5,
//   //   available_spots: 2,
//   //   updated_at: new Date().toISOString()
//   // });

//   const data = fs.readFileSync(dataPath, 'utf8');
//   const parsedData = JSON.parse(data);
//   res.json(parsedData);
// });

app.get('/parking', (req, res) => {
  const userId = req.query.user_id;

  const raw = fs.readFileSync(dataPath, 'utf8');
  const payload = JSON.parse(raw);

  payload.forEach(lot => {
    lot.parking_status = lot.parking_status.map(spot => {
      const claimer = claimedSpots.get(spot.spot_id);
      if (claimer === userId) {
        return { ...spot, status: 'claimed' }; 
      } else if (claimer) {
        return { ...spot, status: 'taken' };   
      }
      return spot;                             
    });
  });

  res.json(payload);
});


app.get('/dashboard', (req,res) => {
  res.sendFile(path.join(__dirname, 'scripts', 'dashboard.html'));
});

const PORT = process.env.PORT || 3000;
// app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

(async () => {
  try {
    await runMigrations();
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
    console.log(` 

             _____ _______       ____  _      ______  _____ 
            / ____|__   __|/\   |  _ \| |    |  ____|/ ____|
          | (___    | |  /  \  | |_) | |    | |__  | (___  
            \___ \   | | / /\ \ |  _ <| |    |  __|  \___ \ 
            ____) |  | |/ ____ \| |_) | |____| |____ ____) |
          |_____/   |_/_/    \_\____/|______|______|_____/ 
                                                            
                                                  
      
      
                                                  \#    #
                                              %%% ##   ##
                                           %%%%% ###%%###
                                          %%%%% ### %%% #
                                        %%%%%% ### %%% ###
                                         %%%% ## %% #######
                                        %%%%% # %% #O#####
                                      %%%%%% # % #########
                                     %%%%% ##### #########
                           ###        %% ####### #########
                  %%% ############    ########### ########
               %%%% ############################### #######
             %%%%% ################################## ######
           %%%%%% #################################### #C###
          %%%%%% #####################################  ###
          %%%%% #######################################
         %%%%%% ########################################
      % %%%%%%% ########################################
       %%%%%%%%% #######################################
      %%%%%%%%%% ########################################
   %%% %%%%%%%%   ###### ################################
     %%%%%%%%      ###### #################### ##########
  % %%%%%%%%        ####### ########### ###### ##########
   %%%%%%%%%         #######  ########### ###### ########
  %%%%%%%%%%          ##### ###  ######### ####### ######
   %%%%%%%%%%          #### ##               ####### ####
   %%%%%%%%%%%           ## #                  ##### ###
    %%  %% % %%         # ##                      ## ###
      %   %    %        # ###                      # ###
                         # ###                     ## ###
                         # ###                     ## ###
                         # ####                   #### ##
                        ### ###                  ##### ###
                       ####  ###                 ####   ##
                      #####   ###                 ##    ##
                     #####    ####                      ###
                      ##        ###                     ###
                                 ####                     ##
                                  ####                    ###
                                                          ####
                                                      	   ##`)
  } catch (err) {
    console.error('Server startup aborted due to migration failure:', err.message);
    process.exit(1);
  }
})();