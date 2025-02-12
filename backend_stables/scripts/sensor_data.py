import json
import random as rand
import datetime


def generate_data():
    print("Generating data...")

    parking_lots = [
        {"lot_id": "Lot_A", "zone_id": "zone_1", "total_spots": 50},
        {"lot_id": "Lot_B","zone_id": "zone_2" ,"total_spots": 30},
        {"lot_id": "Lot_C","zone_id": "zone_3" ,"total_spots": 40}
    ]

    simulated_data = []

    for lot in parking_lots:
        total_spots = lot["total_spots"]
        available_spots = rand.randint(0,total_spots)


        parking_status = []
        for i in range(1, total_spots + 1):
            status = "available" if i <= available_spots else "occupied"
            parking_status.append({
                "spot_id": f"{lot['lot_id']}_Spot_id_{i}",
                "status": status
            })

        parking_data = {
            "lot_id": lot["lot_id"],
            "zone_type": lot["zone_id"],
            "total_spots": total_spots,
            "available_spots": available_spots,
            "updated_at": str(datetime.datetime.utcnow()),
            "parking_status": parking_status
        }

        simulated_data.append(parking_data)

        # print(f"parking id: {lot["lot_id"]} total lots: {lot["total_spots"]}")

    with open("data/simulated_data.json", "w") as f:
        json.dump(simulated_data, f, indent=4)
    print("...data generated")
generate_data()