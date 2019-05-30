import sys
import os
import csv
import json
import math

from x5learn_server.db.database import db_session, engine

from x5learn_server.models import UserLogin, Role, User, Oer, Chunk, Topic


# Initial OER data from CSV files
CSV_DATA_DIR = os.environ['X5LEARN_DATA_DIRECTORY']


def print_row_counts_for_debugging():
    print('# oers:', Oer.query.count())
    print('# chunks:', Chunk.query.count())
    print('# topics:', Topic.query.count())


def load_initial_dataset_from_csv():
    global db_session
    Topic.query.delete();
    Chunk.query.delete();
    Oer.query.delete();
    db_session.commit()
    print_row_counts_for_debugging()
    load_oers_from_csv_file()
    load_wikichunks_from_json_files()


def load_oers_from_csv_file():
    csv.field_size_limit(sys.maxsize)
    print('loading local OER data...')
    with open(CSV_DATA_DIR + '/oers.csv', newline='') as f:
        for row in csv.DictReader(f, delimiter='\t'):
            if not row['title']:
                continue  # omit incomplete items
            url = row['url']
            if db_session.query(Oer.id).filter_by(url=url).scalar() is None: # avoid duplicates
                continue
            row['images'] = json.loads(row['images'].replace("'", '"'))
            row['description'] = '\n'.join([ l for l in row['description'].strip().split('\n') if len(l)>1 ])
            row['date'] = row['date'].replace('Published on ', '') if 'date' in row else ''
            # row['duration'] = human_readable_time_from_ms(float(row['duration'])) if 'duration' in row else ''
            row['duration'] = math.ceil(float(row['duration'])/1000) if 'duration' in row else ''
            del row['wikichunks']  # Use the new wikifier results instead (from the JSON files).
            del row['transcript']  # Delete in order to prevent unnecessary network load when serving OER to the frontend.
            row['mediatype'] = 'video'
            videoid = row['url'].split('v=')[1].split('&')[0]
            url = row['url']
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
                d = json.loads(line)
                video_id = d['videoid']
                # print(video_id)
                oer = Oer.query.filter(Oer.youtube_video_id==video_id)[0]
                chunk = create_chunk_from_dict(d)
                db_session.add(chunk)
                oer.chunks.append(chunk)
                db_session.commit()
    print('Done loading wikichunks')
    import pdb; pdb.set_trace()


def create_chunk_from_dict(d):
    chunk = Chunk(d['start'], d['length'], d['text'])
    annotations = d['annotations']['annotation_data'][:7] # use the top ones, assuming they come sorted by pagerank
    annotations = sorted(annotations, key=lambda a: a['cosine'], reverse=True) # sort them by cosine similarity
    annotations = annotations[:5]
    for a in annotations:
        topic = Topic.query.filter_by(url=a['url']).first()
        if topic is None:
            topic = Topic(a['wikiDataItemId'], a['title'], a['url'])
            db_session.add(topic)
        chunk.topics.append(topic)
    return chunk


# def human_readable_time_from_ms(ms):
#     minutes = int(ms / 60000)
#     seconds = int(ms / 1000 - minutes * 60)
#     return str(minutes) + ':' + str(seconds).rjust(2, '0')
