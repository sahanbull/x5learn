import subprocess, requests, math, json
import textwrap

from wikichunkifiers.lib.util import temp_file_path, EnrichmentError, make_chunk
from wikichunkifiers.lib.wikify import get_entities, WIKIFIER_CHARACTER_LIMIT

def extract_chunks_from_pdf(url):
    print('\nin extract_chunks_from_pdf\n')
    download_file(url)
    # create_thumbnail_and_post_back(url)
    text = convert_to_text()
    if len(text) < 500:
        raise EnrichmentError('Text too short')

    parts = split_text_into_equal_parts(text)

    chunks = []
    start = 0
    for part in parts:
        entities = get_entities(part)
        length = len(part) / len(text)
        chunk = make_chunk(start, length, entities, text)
        # print(json.dumps(chunk, indent=4, sort_keys=True))
        chunks.append(chunk)
        start += length
    return chunks


def download_file(url):
    print('Downloading...')
    r = requests.get(url)
    if r.status_code != 200:
        raise EnrichmentError('Download failed with status '+str(r.status_code))
    with open(pdf_path(), 'wb') as f:
        f.write(r.content)


def convert_to_text():
    args = ["/usr/local/bin/pdftotext",
            '-enc',
            'UTF-8',
            pdf_path(),
            '-',
            ]
    res = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        text = res.stdout.decode('utf-8')
    except UnicodeDecodeError as err:
        raise EnrichmentError('UnicodeDecodeError after pdf conversion')
    return text


def split_text_into_equal_parts(text):
    n_chunks = max( len(text) / WIKIFIER_CHARACTER_LIMIT, int((len(text)/5000) ** 0.7) + 3)
    chunksize = math.ceil(len(text) / n_chunks)
    print('split_text_into_chunks')
    print('len', len(text))
    print('n_chunks', n_chunks)
    print('chunksize', chunksize)
    return [ text[i:i+chunksize] for i in range(0, len(text), chunksize) ]


def pdf_path():
    return temp_file_path('pdf')


# def create_thumbnail_and_post_back(url):
#     args = ["/usr/local/bin/convert",
#             pdf_path(),
#             ]
#     subprocess.check_call(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
#     res = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
#     import pdb; pdb.set_trace()
#     # res = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
#     payload = {'url': url, 'filename': data, 'error': error}
#     r = requests.post(API_ROOT+"ingest_thumbnail/", data=json.dumps(payload))
#     print('create_thumbnail_and_post_back', payload)
