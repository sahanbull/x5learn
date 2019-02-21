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

oer_csv_data = []
stored_concept_names = {}

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
    ensure_csv_data_is_loaded()
    text = request.args['text']
    # return search_results_from_x5gon_api(text)
    return search_results_from_local_experimental_csv(text.lower().split())

@app.route("/api/v1/viewed_fragments/", methods=['GET'])
def api_viewed_fragments():
    ensure_csv_data_is_loaded()
    start, length = (0.1, 0.1)
    fragments = [ create_fragment(oer_csv_data[0], start, length) ]
    return jsonify(fragments)


@app.route("/api/v1/next_steps/", methods=['GET'])
def api_next_steps():
    ensure_csv_data_is_loaded()
    playlists = recommend_next_steps()
    return jsonify(playlists)


@app.route("/api/v1/concept_names/", methods=['GET'])
def concept_names():
    ensure_csv_data_is_loaded()
    concept_ids = request.args['ids'].split(',')
    names = {}
    for concept_id in concept_ids:
        if concept_id in stored_concept_names:
            names[concept_id] = stored_concept_names[concept_id]
        else:
            names[concept_id] = 'Concept not found'
            print('Concept not found:', concept_id)
    return jsonify(names)


def ensure_csv_data_is_loaded():
    if oer_csv_data==[]:
        read_oer_csv_data()
        read_concept_names_from_file()


def search_results_from_local_experimental_csv(search_words):
    results = [ row for row in oer_csv_data if any_word_matches(search_words, row['title']) or any_word_matches(search_words, row['description']) ]
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
            if url in [ r['url'] for r in oer_csv_data ]:
                continue # omit duplicates
            if not row['title']:
                continue # omit incomplete items
            row['images'] = json.loads(row['images'].replace("'", '"'))
            row['date'] = row['date'].replace('Published on ', '') if 'date' in row else ''
            row['duration'] = human_readable_time_from_ms(float(row['duration'])) if 'duration' in row else ''
            oer_csv_data.append(row)


def read_concept_names_from_file():
    global stored_concept_names
    with open('/Users/stefan/x5/data/scenario1/wiki_id_title_mapping.json') as f:
        stored_concept_names = json.load(f)


def human_readable_time_from_ms(ms):
    minutes = int(ms / 60000)
    seconds = int(ms/1000 - minutes*60)
    return str(minutes)+':'+str(seconds)


def create_fragment(oer, start, length):
    return {'oer': oer, 'start': start, 'length': length}


def create_playlist(title, oers):
    return {'title': title, 'oers': oers}


def recommend_next_steps():
    return [ create_playlist("Continue studying", oer_csv_data[50:53]), create_playlist("Videos about Machine Learning", oer_csv_data[1:3]) ]


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
