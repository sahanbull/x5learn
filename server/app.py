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

loaded_oers = []

# oer_csv_path = '/Users/stefan/x5/data/unesco.csv'
# oer_csv_path = '/Users/stefan/x5/data/videolectures_music.csv'
oer_csv_path = '/Users/stefan/x5/data/scenario1/oers.csv'

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
    return search_results_from_local_experimental_csv(text.lower().split())

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
    names = {}

    conn = http.client.HTTPSConnection("www.wikidata.org")
    request_string = '/w/api.php?action=wbgetentities&props=labels&ids=' + '|'.join(entity_ids) + '&languages=en&format=json'
    conn.request('GET', request_string)
    response = conn.getresponse().read().decode("utf-8")
    j = json.loads(response)
    try:
        entities = j['entities']
        for entity_id, value in entities.items():
            names[entity_id] = value['labels']['en']['value']
    except KeyError:
        print('Error trying to retrieve entity labels from wikidata. The server responded with:')
        print(response)
        print('We sent the following ids:', ','.join(entity_ids))
    return jsonify(names)


def setup_initial_data_if_needed():
    if loaded_oers==[]:
        read_oer_csv_data()
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
            self.fragments = [ create_fragment('Lecture 01 - The Learning Problem', 0, 1),
                    create_fragment('Lecture 02 - Is Learning Feasible?', 0, 0.33) ]
        return self.fragments

    def recommended_next_steps(self):
        return [ create_pathway("Continue studying", [ create_fragment('Lecture 02 - Is Learning Feasible?', 0.33, 1-0.33) ]),
            create_pathway("20-minute sprint", [ create_fragment("S18.3 Hoeffding's Inequality", 0, 1) ]),
            create_pathway("10-minute sprint", [ create_fragment('Lecture 02 - Is Learning Feasible?', 0.33, 10/76) ])
            ]


def search_results_from_local_experimental_csv(search_words):
    results = [ row for row in loaded_oers if any_word_matches(search_words, row['title']) or any_word_matches(search_words, row['description']) ]
    return jsonify(results[:18])


def any_word_matches(words, text):
    for word in words:
        if word in text.lower():
            return True
    return False


def read_oer_csv_data():
    csv.field_size_limit(sys.maxsize)
    print('loading local OER data:', oer_csv_path)
    with open(oer_csv_path, newline='') as f:
        for row in csv.DictReader(f, delimiter='\t'):
            url = row['url']
            if url in [ r['url'] for r in loaded_oers ]:
                continue # omit duplicates
            if not row['title']:
                continue # omit incomplete items
            row['images'] = json.loads(row['images'].replace("'", '"'))
            row['date'] = row['date'].replace('Published on ', '') if 'date' in row else ''
            row['duration'] = human_readable_time_from_ms(float(row['duration'])) if 'duration' in row else ''
            loaded_oers.append(row)


def human_readable_time_from_ms(ms):
    minutes = int(ms / 60000)
    seconds = int(ms/1000 - minutes*60)
    return str(minutes)+':'+str(seconds)


def create_fragment(oer_title, start, length):
    oer = find_oer_by_title(oer_title)
    return {'oer': oer, 'start': start, 'length': length}


def create_pathway(rationale, fragments):
    return {'rationale': rationale, 'fragments': fragments}


def find_oer_by_title(title):
    try:
        return [ row for row in loaded_oers if row['title']==title ][0]
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
