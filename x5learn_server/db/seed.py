import sys
import os
import csv
import json
import math

from x5learn_server.db.database import db_session

from x5learn_server.models import UserLogin, Role, GuestUser, Oer


# Initial OER data from CSV files
CSV_DATA_DIR = os.environ['X5LEARN_DATA_DIRECTORY']
loaded_oers = {}
all_entity_titles = set([])


def load_initial_dataset_from_csv():
    global db_session
    global loaded_oers
    # import pdb; pdb.set_trace()
    Oer.query.delete(); db_session.commit()
    load_oers_from_csv_file()
    load_wikichunks_from_json_files()
    print(len(loaded_oers), 'OERs loaded.')
    loaded_oers = {k: v for k, v in loaded_oers.items() if 'wikichunks' in v}
    print(len(loaded_oers), 'OERs left after removing those for which wikichunks data is missing.')
    store_all_entity_titles()


def store_all_entity_titles():
    global all_entity_titles
    for video_id, oer in loaded_oers.items():
        for chunk in oer['wikichunks']:
            for entity in chunk['entities']:
                all_entity_titles.add(entity['title'])


def load_oers_from_csv_file():
    csv.field_size_limit(sys.maxsize)
    print('loading local OER data...')
    with open(CSV_DATA_DIR + '/oers.csv', newline='') as f:
        for row in csv.DictReader(f, delimiter='\t'):
            url = row['url']
            if url in loaded_oers:
                continue  # omit duplicates
            if not row['title']:
                continue  # omit incomplete items
            row['images'] = json.loads(row['images'].replace("'", '"'))
            row['description'] = '\n'.join([ l for l in row['description'].strip().split('\n') if len(l)>1 ])
            row['date'] = row['date'].replace('Published on ', '') if 'date' in row else ''
            # row['duration'] = human_readable_time_from_ms(float(row['duration'])) if 'duration' in row else ''
            row['duration'] = math.ceil(float(row['duration'])/1000) if 'duration' in row else ''
            del row['wikichunks']  # Use the new wikifier results instead (from the JSON files).
            del row['transcript']  # Delete in order to prevent unnecessary network load when serving OER to the frontend.
            row['mediatype'] = 'video'
            videoid = row['url'].split('v=')[1].split('&')[0]
            # loaded_oers[videoid] = row
            # print('loaded: ', row)
            url = row['url']
            # print(111)
            # Oer.query.delete()
            # db_session.commit()
            if db_session.query(Oer.id).filter_by(url=url).scalar() is None:
                # print(222)
                origin = 'YOUTUBE_VARIOUS' if 'youtu' in row['provider'] else 'YOUTUBE_'+row['provider'].replace(' ', '_')
                oer = Oer(url, row, origin, None, videoid)
                db_session.add(oer)
                db_session.commit()
                print('saved', origin, row['title'])
    print('Done loading oers')


def load_wikichunks_from_json_files():
    print('Loading local wikichunk data...')
    dir_path = CSV_DATA_DIR + '/youtube_enrichments/'
    (_, _, filenames) = next(os.walk(dir_path))
    for filename in filenames:
        print('json file:', filename)
        with open(dir_path + filename, newline='') as f:
            for line in f:
                chunk = json.loads(line)
                oer = Oer.query.filter(Oer.youtube_video_id==chunk['videoid'])[0]
                if oer.chunks is None:
                    oer.chunks = { 'compact': [] }
                else:
                    oer.chunks['compact'].append(encode_chunk_to_compact_format(chunk))
                    oer.chunks = dict(oer.chunks) # see https://stackoverflow.com/a/53977819/2237986
                    # print(oer.chunks)
                db_session.commit()
    print('Done loading wikichunks')


def encode_chunk_to_compact_format(chunk):
    annotations = chunk['annotations']['annotation_data']
    annotations = annotations[:7]  # use the top ones, assuming they come sorted by pagerank
    annotations = sorted(annotations, key=lambda a: a['cosine'], reverse=True)
    entities = []
    for a in annotations:
        try:
            entities.append({'id': a['wikiDataItemId'], 'title': a['title'], 'url': a['url']})
        except (NameError, TypeError):
            pass
    entities = entities[:5]
    return {'start': chunk['start'], 'length': chunk['length'], 'entities': entities}


# def human_readable_time_from_ms(ms):
#     minutes = int(ms / 60000)
#     seconds = int(ms / 1000 - minutes * 60)
#     return str(minutes) + ':' + str(seconds).rjust(2, '0')


