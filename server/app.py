from flask import Flask, jsonify, render_template, url_for, request
import urllib
import json
import http.client
from shutil import copyfile
import sys
import os
import re
import csv
import ast # parsing JSON with complex quotation https://stackoverflow.com/a/21154138

app = Flask( __name__ )

loaded_oers = {}


@app.route("/")
def home():
    return render_template('home.html')

@app.route("/search")
def search():
    return render_template('home.html')

@app.route("/next_steps")
def next_steps():
    return render_template('home.html')

@app.route("/journeys")
def journeys():
    return render_template('home.html')

@app.route("/bookmarks")
def bookmarks():
    return render_template('home.html')

@app.route("/history")
def history():
    return render_template('home.html')

@app.route("/notes")
def notes():
    return render_template('home.html')

@app.route("/peers")
def peers():
    return render_template('home.html')


@app.route("/api/v1/search/", methods=['GET'])
def api_search():
    setup_initial_data_if_needed()
    text = request.args['text']
    # return search_results_from_x5gon_api(text)
    return search_results_from_experimental_local_oer_data(text.lower().split())

@app.route("/api/v1/viewed_fragments/", methods=['GET'])
def api_viewed_fragments():
    setup_initial_data_if_needed()
    return jsonify(dummy_user.viewed_fragments())


@app.route("/api/v1/next_steps/", methods=['GET'])
def api_next_steps():
    setup_initial_data_if_needed()
    playlists = dummy_user.recommended_next_steps()
    return jsonify(playlists)


@app.route("/api/v1/entity_labels/", methods=['GET'])
def api_entity_labels():
    entity_ids = request.args['ids'].split(',')
    labels = {}
    descriptions = {}
    conn = http.client.HTTPSConnection("www.wikidata.org")
    # request_string = '/w/api.php?action=wbgetentities&props=labels|descriptions|sitelinks&ids=' + '|'.join(entity_ids) + '&languages=en&sitefilter=enwiki&languagefallback=1&format=json'
    request_string = '/w/api.php?action=wbgetentities&props=labels|descriptions&ids=' + '|'.join(entity_ids) + '&languages=en&sitefilter=enwiki&languagefallback=1&format=json'
    conn.request('GET', request_string)
    response = conn.getresponse().read().decode("utf-8")
    j = json.loads(response)
    try:
        entities = j['entities']
        for entity_id, value in entities.items():
            try:
                labels[entity_id] = value['labels']['en']['value']
            except KeyError:
                labels[entity_id] = '(Concept unavailable)'
                print('WARNING: entity', entity_id, 'has no label.')
            try:
                descriptions[entity_id] = value['descriptions']['en']['value']
                print('WARNING: entity', entity_id, 'has no description.')
            except KeyError:
                descriptions[entity_id] = '(Description unavailable)'
    except KeyError:
        print('Error trying to retrieve entity labels from wikidata. The server responded with:')
        print(response)
        print('We sent the following ids:', ','.join(entity_ids))
    return jsonify({'labels': labels, 'descriptions': descriptions})


def setup_initial_data_if_needed():
    if len(loaded_oers)==0:
        read_local_oer_data()
        setup_dummy_user()


def setup_dummy_user():
    global dummy_user
    dummy_user = DummyUser()


class DummyUser:
    def __init__(self):
        self.fragments = None

    def viewed_fragments(self):
        if not self.fragments:
            print('creating viewed fragments')
            # self.fragments = [ create_fragment('Lecture 01 - The Learning Problem', 0, 1), create_fragment('Lecture 02 - Is Learning Feasible?', 0, 0.33) ]
            self.fragments = [ create_fragment('Lecture 02 - Is Learning Feasible?', 0, 0.33) ]
        return self.fragments

    def recommended_next_steps(self):
        return [ create_pathway("Continue studying", [ create_fragment('Lecture 02 - Is Learning Feasible?', 0.33, 1-0.33) ]),
            create_pathway("20-minute sprint", [ create_fragment("S18.3 Hoeffding's Inequality", 0, 1) ]),
            create_pathway("10-minute sprint", [ create_fragment('Lecture 02 - Is Learning Feasible?', 0.33, 10/76) ])
            ]


def search_results_from_experimental_local_oer_data(search_words):
    results = [ oer for oer in loaded_oers.values() if any_word_matches(search_words, oer['title']) or any_word_matches(search_words, oer['description']) or any_word_matches(search_words, entity_ids_from_chunks(oer)) ]
    return jsonify(results[:18])


def entity_ids_from_chunks(oer):
    return ' '.join(re.findall(r'Q\d+', oer['wikichunks']))


def any_word_matches(words, text):
    for word in words:
        if word in text.lower():
            return True
    return False


def read_local_oer_data():
    load_oers_from_csv_file()
    load_wikichunks_from_json_files()


def load_oers_from_csv_file():
    csv.field_size_limit(sys.maxsize)
    print('loading local OER data...')
    with open('/Users/stefan/x5/data/scenario1/oers.csv', newline='') as f:
        for oer in csv.DictReader(f, delimiter='\t'):
            url = oer['url']
            if url in loaded_oers:
                continue # omit duplicates
            if not oer['title']:
                continue # omit incomplete items
            oer['images'] = json.loads(oer['images'].replace("'", '"'))
            oer['date'] = oer['date'].replace('Published on ', '') if 'date' in oer else ''
            oer['duration'] = human_readable_time_from_ms(float(oer['duration'])) if 'duration' in oer else ''
            videoid = oer['url'].split('v=')[1].split('&')[0]
            loaded_oers[videoid] = oer
    print('Done loading oers')


def load_wikichunks_from_json_files():
    print('Loading local wikichunk data...')
    dir_path = '/Users/stefan/x5/data/scenario1/youtube_enrichments/'
    (_, _, filenames) = next(os.walk(dir_path))
    for filename in filenames:
        with open(dir_path+filename, newline='') as f:
            for line in f:
                chunk = json.loads(line)
                oer = loaded_oers[chunk['videoid']]
                if not 'jsonchunks' in oer:
                    oer['jsonchunks'] = []
                oer['jsonchunks'].append(chunk)
    print('Done loading wikichunks')
    print('______________')
    print('Encoding wikichunks')
    for videoid,oer in loaded_oers.items():
        if not 'jsonchunks' in oer:
            print('WARNING: oer has no jsonchunks', videoid)
        else:
            chunks = []
            json_chunks = oer['jsonchunks']
            last_chunk = json_chunks[-1]
            duration = last_chunk['start'] + last_chunk['length']
            # if videoid=='PPDWaZPu7MU':
            #     print(duration)
            #     print(len(json_chunks))
            #     print(json_chunks[3]['annotations']['annotation_data'][:5])
            #     print(last_chunk['annotations']['annotation_data'][:5])
            for j in json_chunks:
                annotations = j['annotations']['annotation_data']
                annotations = annotations[:7] # use the top ones, assuming they come sorted by pagerank
                annotations = sorted(annotations, key=lambda a: a['cosine'], reverse=True)
                concept_ids = [ a['wikiDataItemId'] for a in annotations if 'wikiDataItemId' in a ][:5]
                chunks.append(encode_chunk(j['start'], j['length'], concept_ids, duration))
            oer['wikichunks'] = '&'.join(chunks)
    print('______________')
    print('Done encoding wikichunks')


def encode_chunk(start_second, length_seconds, concept_ids, duration):
    start = round(start_second / duration, 4)
    length = round(length_seconds / duration, 4)
    return str(start)+','+str(length)+':'+','.join(concept_ids)


def human_readable_time_from_ms(ms):
    minutes = int(ms / 60000)
    seconds = int(ms/1000 - minutes*60)
    return str(minutes)+':'+str(seconds).rjust(2, '0')


def create_fragment(oer_title, start, length):
    oer = find_oer_by_title(oer_title)
    return {'oer': oer, 'start': start, 'length': length}


def create_pathway(rationale, fragments):
    return {'rationale': rationale, 'fragments': fragments}


def find_oer_by_title(title):
    try:
        return [ oer for oer in loaded_oers.values() if oer['title']==title ][0]
    except IndexError:
        print('No OER was found with title', title)


# def search_results_from_x5gon_api(text):
#     encoded_text = urllib.parse.quote(text)
#     conn = http.client.HTTPSConnection("platform.x5gon.org")
#     conn.request('GET', '/api/v1/search/?url=https://platform.x5gon.org/materialUrl&text='+encoded_text)
#     response = conn.getresponse().read().decode("utf-8")
#     recommendations = json.loads(response)['recommendations'][:9]
#     return jsonify(recommendations)


# THUMBNAILS FOR X5GON (experimental)

# def project_folder():
#     return '/Users/stefan/x5/prototypes/60_x5learn_mountains/'

# def image_filename(resource_url):
#     return 'thumbnail_' + re.sub('[^a-zA-Z0-9]', '_', resource_url) + '.jpg'

# def thumbnail_local_path_1(resource_url):
#     return project_folder() + 'assets/img/' + image_filename(resource_url)

# def thumbnail_local_path_2(resource_url):
#     return project_folder() + 'server/static/dist/img/' + image_filename(resource_url)

# def thumbnail_url(resource_url):
#     return 'dist/img/' + image_filename(resource_url)


# def create_thumbnail(resource_url):
#     dummy_file_path = project_folder() + 'assets/img/thumbnail_unavailable.jpg'
#     copyfile(dummy_file_path, thumbnail_local_path_1(resource_url))
#     copyfile(dummy_file_path, thumbnail_local_path_2(resource_url))


# @app.route("/<path:anything>")
# def product(anything):
#     return render_template('home.html')


if __name__ == ' __main__':
    app.run()
