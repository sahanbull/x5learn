import requests, json

from wikichunkifiers.lib.util import EnrichmentError

WIKIFIER_CHARACTER_LIMIT = 24999

def get_entities(text):
    if len(text)>WIKIFIER_CHARACTER_LIMIT:
        print('Warning: Character limit exceeded. Text truncated.')
        text = text [:WIKIFIER_CHARACTER_LIMIT]
    payload = {'userKey': 'yeydkrkxbnrfxcgayvanalxesqqwja',
               'text': text,
               'lang': 'auto',
               'support': 'false',
               'ranges': 'false',
               'includeCosines': 'true',
               'nTopDfValuesToIgnore': 50,
               'nWordsToIgnoreFromList': 50,
              }
    r = requests.post("http://www.wikifier.org/annotate-article", data=payload)
    try:
        j = json.loads(r.text)
    except json.decoder.JSONDecodeError as err:
        # print('_______________________________________')
        # print(r.text)
        # print('_______________________________________')
        # print(text)
        # print('_______________________________________')
        # print(err)
        # raise
        raise EnrichmentError('JSONDecodeError')
    if not 'annotations' in j:
        # print('json =', j)
        raise EnrichmentError('No annotations')
    annotations = sorted(j['annotations'], key=lambda k: k['pageRank'], reverse=True)[:5]
    entities = []
    for a in annotations:
        if 'wikiDataItemId' in a:
            entities.append({'id': a['wikiDataItemId'],
                             'title': a['title'],
                             'definition': '',
                             'url': a['url'],
                             })
    if entities==[]:
        raise EnrichmentError('No entities found in text fragment')
    return entities
