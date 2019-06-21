import requests
import json
from time import sleep

from wikichunkifiers.pdf import extract_chunks_from_pdf
from wikichunkifiers.youtube import extract_chunks_from_youtube_video
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
            if 'data' in j:
                oer_data = j['data']
                url = oer_data['url']
                enrichment_data, error = make_enrichment_data(oer_data)
                post_back_wikichunks(url, enrichment_data, error)
            elif 'info' in j:
                say(j['info'])
                sleep(2)
            else:
                say('Response is missing essential fields')
                sleep(60)
        except requests.exceptions.ConnectionError:
            say('ConnectionError caught - waiting for main app to respond.')
            sleep(5)
        # except Exception as err:
        #     print("Error: {0}".format(err))
        #     say('Something went wrong. Waiting.')
        #     sleep(5)


def say(text):
    print('X5Learn Enrichment Worker says:', text)


def make_enrichment_data(oer_data):
    data = { 'chunks': [], 'errors': False }
    error = None
    try:
        data['chunks'] = make_wikichunks(oer_data)
    except EnrichmentError as err:
        error = err.message
        data['errors'] = True
    return data, error


def make_wikichunks(oer_data):
    print('\n_______________________________________________________________________________')
    url = oer_data['url']
    print(url)
    if url.lower().endswith('.pdf'):
        return extract_chunks_from_pdf(url)
    if 'youtu' in url and '/watch?v=' in url:
        return extract_chunks_from_youtube_video(url, oer_data)
    raise EnrichmentError('Unsupported file format')


def post_back_wikichunks(url, data, error):
    payload = {'url': url, 'data': data, 'error': error}
    r = requests.post(API_ROOT+"ingest_wikichunk_enrichment/", data=json.dumps(payload))
    # print('post_back_wikichunks', payload)


if __name__ == '__main__':
    main()
