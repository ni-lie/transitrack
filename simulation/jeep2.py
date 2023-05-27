import random
from google.cloud import firestore_v1
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import time
import math

# Set the path to your service account key JSON file
cred = credentials.Certificate("D:\CS 145\TransiTrack\simulation\Transitrack.json")

firebase_admin.initialize_app(cred)
db = firestore.client()

# Define the collection and document names
collection_name = 'jeeps_realtime'
document_name = 'jeep1'
subcollection_path = f'jeeps_historical/{document_name}/timeline'

coordinates = [
    [14.657675, 121.062360],
    [14.654756, 121.062316],
    [14.647361, 121.062336],
    [14.647706, 121.063844],
    [14.647659, 121.064632],
    [14.647939, 121.065780],
    [14.647960, 121.066328],
    [14.647254, 121.067808],
    [14.647173, 121.068955],
    [14.649071, 121.068951],
    [14.649904, 121.068611],
    [14.650504, 121.068453],
    [14.650908, 121.068430],
    [14.651842, 121.068584],
    [14.652487, 121.068667],
    [14.652550, 121.072847],
    [14.653974, 121.072828],
    [14.654645, 121.073132],
    [14.655566, 121.073090],
    [14.656308, 121.072771],
    [14.659379, 121.072722],
    [14.659390, 121.068572],
    [14.657539, 121.068584],
    [14.657568, 121.064787]
]

def calculate_bearing(coordinate1, coordinate2):
    x1, y1 = coordinate1
    x2, y2 = coordinate2

    delta_x = x2 - x1
    delta_y = y2 - y1

    bearing = math.atan2(delta_y, delta_x)
    bearing_degrees = math.degrees(bearing)

    # Adjust the bearing to be in the range of 0 to 360 degrees
    bearing_degrees = (bearing_degrees + 360) % 360

    return bearing_degrees


# Create the document
def update_create_document(count):
    doc_ref_realtime = db.collection(collection_name).document(document_name)
    doc_ref_historical = db.collection(subcollection_path).document()

    embark = random.choice([True, False])
    passenger_count = random.randint(0, 16)
    random_x = random.uniform(-0.00004, 0.00004)
    random_y = random.uniform(-0.00004, 0.00004)

    if count == 0: pos1 = coordinates[len(coordinates)-1]
    else: pos1 = coordinates[count-1]
    bearing = calculate_bearing(pos1, coordinates[count])
    # Define the data to be added to the document

    data = {
        'acceleration': [random.uniform(0, 150) for _ in range(3)],
        'air_qual': random.uniform(0, 1200),
        'device_id': document_name,
        'disembark': not embark,
        'embark': embark,
        'gyroscope': [bearing, 0, 0],
        'is_active': True,
        'location': firestore_v1.GeoPoint(coordinates[count][0] + random_x, coordinates[count][1] + random_y),
        'passenger_count': passenger_count,
        'route_id': 0,
        'slots_remaining': 16 - passenger_count, 
        'speed': random.uniform(0, 150),
        'temp': random.uniform(26, 33),
        'timestamp': firestore.SERVER_TIMESTAMP
    }
    # Set the data in the document
    doc_ref_realtime.set(data)
    doc_ref_historical.set(data)
    print(f"Document updated and created successfully.")

count = random.randint(0, len(coordinates)-1)


while True:
    if count >= len(coordinates): count = 0
    update_create_document(count)
    count+=1
    time.sleep(5)