import json
import random as rand
import datetime
import sys
import os

def determine_occupancy(total_spots, current_minutes): 
    # Define time slots in minutes since midnight:
    # Slot 1: 7:00 (420) to 9:30 (570)       -> Lower traffic
    # Slot 2: 9:30 (570) to 12:00 (720)       -> Highest traffic
    # Slot 3: 12:00 (720) to 15:30 (930)       -> Second highest traffic
    # Slot 4: 15:30 (930) to 17:00 (1020)      -> Medium traffic
    # Slot 5: 17:00 (1020) to 7:00 (420 next day) -> Lowest traffic

    if 420 <= current_minutes < 570:           # Slot 1 8:00 am 8.0
        occupancy = rand.uniform(0.40, 0.55)
    elif 570 <= current_minutes < 720:         # Slot 2 10:00 am 10.0
        occupancy = rand.uniform(0.85, 0.95)
    elif 720 <= current_minutes < 930:         # Slot 3 2:00 pm 14.0
        occupancy = rand.uniform(0.80, 0.90)
    elif 930 <= current_minutes < 1020:        # Slot 4 4:00 pm 16.0
        occupancy = rand.uniform(0.60, 0.75)
    else:                                      # Slot 5 8:00 pm 20.0
        occupancy = rand.uniform(0.20, 0.35)
    return occupancy

def update_state(prev_state, target_available, total_spots, lot_id):
    # parking stats -> dictonary
    prev_status = {spot["spot_id"]: spot["status"] for spot in prev_state} if prev_state else {}

    # spot id list
    spot_ids = [f"{lot_id}_Spot_{i}" for i in range(1, total_spots + 1)]
    new_status = {}

    for spot_id in spot_ids:
        # 20% chance to flip status
        if rand.random() < 0.2:
            prev = prev_status.get(spot_id, "occupied")
            new_status[spot_id] = "available" if prev == "occupied" else "occupied"
        else:
            new_status[spot_id] = prev_status.get(spot_id, "occupied")

    # meet target
    current_available = sum(1 for s in new_status.values() if s == "available")
    while current_available > target_available:
        available_spots = [spot for spot, status in new_status.items() if status == "available"]
        spot_to_flip = rand.choice(available_spots)
        new_status[spot_to_flip] = "occupied"
        current_available -= 1
    while current_available < target_available:
        occupied_spots = [spot for spot, status in new_status.items() if status == "occupied"]
        spot_to_flip = rand.choice(occupied_spots)
        new_status[spot_to_flip] = "available"
        current_available += 1
    parking_status = [{"spot_id": spot_id, "status": new_status[spot_id]} for spot_id in spot_ids]
    return parking_status


def generate_data(debug_mode = None):
    print("Generating data...")

    now = datetime.datetime.now()
    current_minutes = debug_mode if debug_mode is not None else now.hour * 60 + now.minute


    parking_lots = [
        {"lot_id": "Lot_A", "zone_id": "zone_1", "total_spots": 50},
        {"lot_id": "Lot_B","zone_id": "zone_2" ,"total_spots": 30},
        {"lot_id": "Lot_C","zone_id": "zone_3" ,"total_spots": 40}
    ]

    # prev data
    prev_data_file = "backend_stables/data/simulated_data.json"
    prev_data = None
    if os.path.exists(prev_data_file):
        with open(prev_data_file, "r") as f:
            prev_data = json.load(f)


    simulated_data = []

    for lot in parking_lots:
        total_spots = lot["total_spots"]
        occupancy_rate = determine_occupancy(total_spots, current_minutes)
        target_available = int(total_spots * (1 - occupancy_rate))

        prev_lot = None
        if prev_data:
            for l in prev_data:
                if l["lot_id"] == lot["lot_id"]:
                    prev_lot = l["parking_status"]
                    break

        parking_status = update_state(prev_lot, target_available, total_spots, lot["lot_id"])


        # spots = list(range(1, total_spots + 1))
        # rand.shuffle(spots)
        # available_set = set(spots[:available_spots])


        # parking_status = []
        # for i in range(1, total_spots + 1):
        #     status = "available" if i in available_set else "occupied"
        #     parking_status.append({
        #         "spot_id": f"{lot['lot_id']}_Spot_id_{i}",
        #         "status": status
        #     })

        parking_data = {
            "lot_id": lot["lot_id"],
            "zone_type": lot["zone_id"],
            "total_spots": total_spots,
            "available_spots": target_available,
            "updated_at": str(datetime.datetime.now(datetime.timezone.utc)),
            "parking_status": parking_status
        }

        simulated_data.append(parking_data)

        # print(f"parking id: {lot["lot_id"]} total lots: {lot["total_spots"]}")

    with open("data/simulated_data.json", "w") as f:
        json.dump(simulated_data, f, indent=4)
    print("...data generated")

if __name__ == "__main__":

    debug_mode = None

    if len(sys.argv) > 1:
        try:
            debug_hour = float(sys.argv[1].strip())
            debug_mode = int(debug_hour * 60)
            print(f"Debug mode: Simulating data for hour {debug_hour} (i.e. {debug_mode} minutes)")
        except ValueError:
            print("Invalid debug hour argument. Using current time.")

    generate_data(debug_mode)