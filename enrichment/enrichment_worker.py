import requests
import json
from time import sleep

from wikichunkifiers.pdf import extract_chunks_from_pdf
from wikichunkifiers.lib.util import EnrichmentError

import os

API_ROOT = os.environ["FLASK_API_ROOT"]
# API_ROOT = 'http://127.0.0.1:5000/api/v1/'


def main():
    say('hello')
    while(True):
        payload = {}
        try:
            r = requests.post(API_ROOT+"most_urgent_unstarted_enrichment_task/", data=payload)
            j = json.loads(r.text)
            if 'url' in j:
                url = j['url']
                data, error = make_enrichment_data(url)
                post_back_wikichunks(url, data, error)
            elif 'info' in j:
                say(j['info'])
                sleep(2)
        except requests.exceptions.ConnectionError:
            say('ConnectionError caught - waiting for main app to respond.')
            sleep(5)
        except:
            say('Something went wrong. Waiting.')
            sleep(5)


def say(text):
    print('X5Learn Enrichment Worker says:', text)


def make_enrichment_data(url):
    data = { 'chunks': [], 'errors': False }
    error = None
    try:
        data['chunks'] = make_wikichunks(url)
    except EnrichmentError as err:
        error = err.message
        data['errors'] = True
    return data, error


def make_wikichunks(url):
    print('\n_______________________________________________________________________________')
    print(url)
    if url.lower().endswith('.pdf'):
        return extract_chunks_from_pdf(url)
    raise EnrichmentError('Unsupported file format')


def post_back_wikichunks(url, data, error):
    payload = {'url': url, 'data': data, 'error': error}
    r = requests.post(API_ROOT+"ingest_wikichunk_enrichment/", data=json.dumps(payload))
    # print('post_back_wikichunks', payload)


if __name__ == '__main__':
    main()
