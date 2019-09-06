import requests, math, json, os, sys, re

from wikichunkifiers.lib.util import temp_file_path, EnrichmentError, make_chunk
from wikichunkifiers.lib.wikify import get_entities, WIKIFIER_CHARACTER_LIMIT


def extract_chunks_from_generic_text(url, data):
    print('\nin extract_chunks_from_generic_text\n')
    text = '. '.join([ data['title'], data['description'] ])
    if len(text) < 500:
        raise EnrichmentError('Text too short')

    parts = split_text_into_equal_parts(text)

    chunks = []
    start = 0
    for index, part in enumerate(parts):
        print('Processing chunk', index+1, '/', len(parts))
        entities = get_entities(part)
        length = len(part) / len(text)
        chunk = make_chunk(start, length, entities, part)
        # print(json.dumps(chunk, indent=4, sort_keys=True))
        chunks.append(chunk)
        start += length
    return chunks


def split_text_into_equal_parts(text):
    n_chunks = max( len(text) / WIKIFIER_CHARACTER_LIMIT, int((len(text)/5000) ** 0.7) + 3)
    chunksize = math.ceil(len(text) / n_chunks)
    print('split_text_into_chunks')
    print('len', len(text))
    print('n_chunks', n_chunks)
    print('chunksize', chunksize)
    return [ text[i:i+chunksize] for i in range(0, len(text), chunksize) ]
