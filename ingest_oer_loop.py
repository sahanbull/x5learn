import argparse
import requests
import json
import os


API_URL = os.environ["FLASK_API_ROOT"]

HEADERS = {
    'accept': 'application/json',
    'Content-Type': 'application/json',
}

ENDPOINT = 'ingest_oer/'

if __name__ == '__main__':
    parser=argparse.ArgumentParser(
        description='''X5Learn script for importing all OERs from X5GON. It loops through a range of material_ids. For each material_id, it sends a request to our flask app, causing it to: (1) Create an X5Learn OER record, (2) push an enrichment task to the queue.''',
        epilog="""NB existing OERs won't be overwritten.""")
    parser.add_argument('start', type=str, help='first material_id in the range. Must be >= 1')
    parser.add_argument('end', type=str, help='last material_id in the range. Must be >= start')
    args=parser.parse_args()

    material_id = int(args.start)
    end_id = int(args.end)
    while material_id <= end_id:
        print('\n______________________________________________________________')
        print('material_id', material_id)
        data = {'material_id': material_id}
        response = requests.post(API_URL + ENDPOINT,
                             headers= HEADERS,
                             data=json.dumps(data))
        response_json = response.json()
        print(response_json)
        material_id += 1
