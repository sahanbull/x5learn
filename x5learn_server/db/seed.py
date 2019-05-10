import sys
import os
import csv
import json

from x5learn_server.db.database import db_session

from x5learn_server.models import UserLogin, Role, GuestUser, Oer


# Initial OER data from CSV files
CSV_DATA_DIR = os.environ['X5LEARN_DATA_DIRECTORY']
loaded_oers = {}
all_entity_titles = set([])


def load_initial_dataset_from_csv():
    global db_session
    global loaded_oers
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
            row['duration'] = human_readable_time_from_ms(float(row['duration'])) if 'duration' in row else ''
            del row['wikichunks']  # Use the new wikifier results instead (from the JSON files).
            del row[
                'transcript']  # Delete in order to prevent unnecessary network load when serving OER to the frontend.
            row['mediatype'] = 'video'
            videoid = row['url'].split('v=')[1].split('&')[0]
            # loaded_oers[videoid] = row
            #TODO
            print('loaded: ', row)
            url = row['url']
            print(111)
            if db_session.query(Oer.id).filter_by(url=url).scalar() is None:
                print(222)
                oer = Oer(url, row, 'YOUTUBE_ML', None)
                db_session.add(oer)
                db_session.commit()
            print(333)
            print(Oer.query.all())
            print(444)
            import pdb; pdb.set_trace()
            break



    print('Done loading oers')


def load_wikichunks_from_json_files():
    chunkdata = {}
    print('Loading local wikichunk data...')
    dir_path = CSV_DATA_DIR + '/youtube_enrichments/'
    (_, _, filenames) = next(os.walk(dir_path))
    for filename in filenames:
        with open(dir_path + filename, newline='') as f:
            for line in f:
                chunk = json.loads(line)
                oer = loaded_oers[chunk['videoid']]
                url = oer['url']
                if not url in chunkdata:
                    chunkdata[url] = []
                chunkdata[url].append(chunk)
    print('Done loading wikichunks')
    print('______________')
    print('Encoding wikichunks')
    for videoid, oer in loaded_oers.items():
        url = oer['url']
        if not url in chunkdata:
            # print('WARNING: oer has no JSON chunks', videoid)
            pass
        else:
            json_chunks = chunkdata[url]
            chunks = []
            last_chunk = json_chunks[-1]
            duration = last_chunk['start'] + last_chunk['length']
            for j in json_chunks:
                annotations = j['annotations']['annotation_data']
                annotations = annotations[:7]  # use the top ones, assuming they come sorted by pagerank
                annotations = sorted(annotations, key=lambda a: a['cosine'], reverse=True)
                entities = []
                for a in annotations:
                    try:
                        entities.append({'id': a['wikiDataItemId'], 'title': a['title'], 'url': a['url']})
                    except (NameError, TypeError):
                        pass
                entities = entities[:5]
                chunks.append(encode_chunk(j['start'], j['length'], entities, duration))
            oer['wikichunks'] = chunks
    print('______________')
    print('Done encoding wikichunks')


def encode_chunk(start_second, length_seconds, entities, duration):
    start = round(start_second / duration, 4)
    length = round(length_seconds / duration, 4)
    return {'start': start, 'length': length, 'entities': entities}


def human_readable_time_from_ms(ms):
    minutes = int(ms / 60000)
    seconds = int(ms / 1000 - minutes * 60)
    return str(minutes) + ':' + str(seconds).rjust(2, '0')


def search_results_from_experimental_local_oer_data(text):
    max_results = 18
    frequencies = defaultdict(int)
    for video_id, oer in loaded_oers.items():
        for chunk in oer['wikichunks']:
            for entity in chunk['entities']:
                if text == entity['title'].lower().strip():
                    frequencies[video_id] += 1
    # import pdb; pdb.set_trace()
    results = [loaded_oers[video_id] for video_id, freq in
               sorted(frequencies.items(), key=lambda k_v: k_v[1], reverse=True)[:max_results]]
    print(len(results), 'search results found based on wikichunks.')
    # if len(results) < max_results:
    #     search_words = text.split()
    #     n = max_results-len(results)
    #     print('Search: adding', n,'results by title and description')
    #     results += [ oer for oer in loaded_oers.values() if any_word_matches(search_words, oer['title']) or any_word_matches(search_words, oer['description']) ][:n]
    return results


