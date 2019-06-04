import requests
import json
from time import sleep

from chunk_extractors.pdf import extract_chunks_from_pdf

API_ROOT = 'http://127.0.0.1:5000/api/v1/'


def main():
    say('hello')
    while(True):
        # payload = {'dummy': '12345'}
        payload = {}
        r = requests.post(API_ROOT+"most_urgent_unstarted_enrichment_task/", data=payload)
        j = json.loads(r.text)
        if 'url' in j:
            url = j['url']
            data, error = make_enrichment_data(url)
            post_back(url, data, error)
        elif 'info' in j:
            say(j['info'])
            sleep(10)


def say(text):
    print('X5Learn Enrichment Worker says:', text)


def make_enrichment_data(url):
    data = { 'wikichunks': [], 'errors': False }
    error = None
    try:
        data['wikichunks'] = make_wikichunks(url)
    except EnrichmentError as err:
        error = err.message
        data['errors'] = True
    return data, error


class EnrichmentError(ValueError):
    def __init__(self, message):
        self.message = message


def make_wikichunks(url):
    if url.endswith('.pdf'):
        return extract_chunks_from_pdf(url)
    raise EnrichmentError('Unsupported file format')


def post_back(url, data, error):
    payload = {'url': url, 'data': data, 'error': error}
    r = requests.post(API_ROOT+"ingest_enrichment_data/", data=json.dumps(payload))
    print('\npost_back', payload)


if __name__ == '__main__':
    main()
