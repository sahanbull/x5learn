from flask import Flask, jsonify, render_template, url_for, request
import urllib
import json
import http.client
from shutil import copyfile
import os
import re
import csv

app = Flask( __name__ )

csv_data = []
# csv_path = '/Users/stefan/x5/data/unesco.csv'
# csv_path = '/Users/stefan/x5/data/videolectures_music.csv'
csv_path = '/Users/stefan/x5/data/scenario_A_ng_bishop.csv'

@app.route("/")
def home():
    return render_template('home.html')

@app.route("/next_steps")
def next_steps():
    return render_template('home.html')

@app.route("/routes")
def routes():
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
def search():
    text = request.args['text']
    # return search_results_from_x5gon_api(text)
    return search_results_from_local_experimental_csv(text.lower().split())


def search_results_from_local_experimental_csv(search_words):
    if csv_data==[]:
        read_csv_data()
    results = [ row for row in csv_data if any_word_matches(search_words, row['title']) or any_word_matches(search_words, row['description']) ]
    return jsonify(results[:18])


def any_word_matches(words, text):
    for word in words:
        if word in text.lower():
            return True
    return False


def read_csv_data():
    print('using local data:', csv_path)
    with open(csv_path, newline='') as f:
        for row in csv.DictReader(f, delimiter='\t'):
            if row['url'] in [ r['url'] for r in csv_data ]:
                continue
            row['youtubeVideoVersions'] = json.loads(row['youtubeVideoVersions'].replace("'", '"'))
            row['imageUrls'] = json.loads(row['imageUrls'].replace("'", '"'))
            row['date'] = row['date'] if 'date' in row else ''
            row['duration'] = row['duration'] if 'duration' in row else ''
            csv_data.append(row)


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
