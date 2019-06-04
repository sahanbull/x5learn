import requests
import json
from time import sleep


API_ROOT = 'http://127.0.0.1:5000/api/v1/'


def main():
    say('hello')
    while(True):
        payload = {'dummy': '12345'}
        r = requests.post(API_ROOT+"most_urgent_unstarted_enrichment_task/", data=payload)
        j = json.loads(r.text)
        if 'data' in j:
            enrich(j['data'])
        elif 'info' in j:
            say(j['info'])
            sleep(10)


def say(text):
    print('X5Learn Enrichment Worker says:', text)


def enrich(data):
    data['wikichunks'] = [ {'start': 0, 'length': 0.5, 'entities': []} ]
    payload = {'data': data}
    r = requests.post(API_ROOT+"ingest_enrichment_data/", data=json.dumps(payload))
    print('sent', payload)


if __name__ == '__main__':
    main()
