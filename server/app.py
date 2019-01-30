from flask import Flask, jsonify, render_template, url_for, request
import urllib
import json
import http.client
from shutil import copyfile
import os
import re
import csv
import ast # parsing JSON with complex quotation https://stackoverflow.com/a/21154138

app = Flask( __name__ )

oer_csv_data = []
wikichunks = {} # key = video_id, value = loaded csv file
bishop_wikichunks = []

# oer_csv_path = '/Users/stefan/x5/data/unesco.csv'
# oer_csv_path = '/Users/stefan/x5/data/videolectures_music.csv'
oer_csv_path = '/Users/stefan/x5/data/ng_youtube_lectures.csv'

youtube_wikichunks_csv_directory = '/Users/stefan/x5/data/wikified_youtube_videos/'
bishop_wikichunks_csv_path = '/Users/stefan/x5/data/bishop_chunks_9000.csv'

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
def api_search():
    ensure_csv_data_is_loaded()
    text = request.args['text']
    # return search_results_from_x5gon_api(text)
    return search_results_from_local_experimental_csv(text.lower().split())

@app.route("/api/v1/viewed_fragments/", methods=['GET'])
def api_viewed_fragments():
    ensure_csv_data_is_loaded()
    start, length = bishop_book_chapter2()
    fragments = [ create_fragment(bishop_book(), start, length) ]
    return jsonify(fragments)


@app.route("/api/v1/next_steps/", methods=['GET'])
def api_next_steps():
    ensure_csv_data_is_loaded()
    playlists = recommend_next_steps()
    return jsonify(playlists)


@app.route("/api/v1/chunks/", methods=['GET'])
def api_chunks():
    ensure_csv_data_is_loaded()
    urls = request.args['urls'].split(',')
    lists = {}
    for url in urls:
        lists[url] = wikichunks[url]
    return jsonify(lists)


def ensure_csv_data_is_loaded():
    if oer_csv_data==[]:
        read_oer_csv_data()
        read_wikifier_data()


def bishop_book():
    return { 'url': "https://www.microsoft.com/en-us/research/people/cmbishop/#!prml-book"
    , 'provider': "https://www.microsoft.com"
    , 'date': "2006"
    , 'title': "Pattern Recognition and Machine Learning"
    , 'duration': ""
    , 'description': "This leading textbook provides a comprehensive introduction to the fields of pattern recognition and machine learning. It is aimed at advanced undergraduates or first-year PhD students, as well as researchers and practitioners. No previous knowledge of pattern recognition or machine learning concepts is assumed. This is the first machine learning textbook to include a comprehensive coverage of recent developments such as probabilistic graphical models and deterministic inference methods, and to emphasize a modern Bayesian perspective. It is suitable for courses on machine learning, statistics, computer science, signal processing, computer vision, data mining, and bioinformatics. This hard cover book has 738 pages in full colour, and there are 431 graded exercises (with solutions available below). Extensive support is provided for course instructors."
    , 'imageUrls': [ "https://www.microsoft.com/en-us/research/wp-content/uploads/2016/06/Springer-Cover-Image-752x1024.jpg" ]
    , 'youtubeVideoVersions': {}
    }


def bishop_book_chapter2():
    # In the wikified book by Bishop, chunks 15-24 (out of 156) contain chapter 2 on probability distributions
    first_chunk = 15
    last_chunk = 24
    n_total_chunks = 156
    start = first_chunk / n_total_chunks
    length = (last_chunk-first_chunk) / n_total_chunks
    return (start, length)

def search_results_from_local_experimental_csv(search_words):
    results = [ row for row in oer_csv_data if any_word_matches(search_words, row['title']) or any_word_matches(search_words, row['description']) ]
    return jsonify(results[:18])


def any_word_matches(words, text):
    for word in words:
        if word in text.lower():
            return True
    return False


def read_oer_csv_data():
    print('loading local OER data:', oer_csv_path)
    with open(oer_csv_path, newline='') as f:
        for row in csv.DictReader(f, delimiter='\t'):
            url = row['url']
            if url in [ r['url'] for r in oer_csv_data ]:
                continue # omit duplicates
            youtube = json.loads(row['youtubeVideoVersions'].replace("'", '"'))
            if not youtube and re.search(r'youtu', url):
                youtube = { 'English': url.split('v=')[1].split('&')[0] }
            row['youtubeVideoVersions'] = youtube
            row['imageUrls'] = json.loads(row['imageUrls'].replace("'", '"'))
            row['date'] = row['date'] if 'date' in row else ''
            row['duration'] = row['duration'] if 'duration' in row else ''
            oer_csv_data.append(row)


def read_wikifier_data():
    dir_path = youtube_wikichunks_csv_directory
    print('loading local wikifier data:', dir_path)
    for file in os.listdir(dir_path):
        filename = dir_path + os.fsdecode(file)
        video_id = filename.split('/')[-1].split('.')[0]
        with open(filename, newline='') as f:
            chunks = []
            for row in csv.DictReader(f, delimiter=','):
                row['topics'] = ast.literal_eval(row['topics'])
                row['start'] = float(row['start'])
                row['length'] = float(row['length'])
                row.pop('')
                chunks.append(row)
        url = 'https://youtube.com/watch?v='+video_id
        wikichunks[url] = chunks
    wikichunks[bishop_book()['url']] = bishop_wikifier_data()


def bishop_wikifier_data():
    print('loading local wikifier data:', bishop_wikichunks_csv_path)
    with open(bishop_wikichunks_csv_path, newline='') as f:
        chunks = []
        rows = []
        for row in csv.DictReader(f, delimiter=','):
            rows.append(row)
        n_rows = len(rows)
        for row in rows:
            chunk = {'start': float(row[''])/n_rows, 'length': 1.0/n_rows, 'topics': [ row['a0title'], row['a1title'], row['a2title'], row['a3title'], row['a4title'] ]}
            chunks.append(chunk)
    return chunks


def create_fragment(oer, start, length):
    return {'oer': oer, 'start': start, 'length': length}


def create_playlist(title, oers):
    return {'title': title, 'oers': oers}


def recommend_next_steps():
    return [ create_playlist("Continue reading", [bishop_book()]), create_playlist("Videos about Machine Learning", oer_csv_data[1:3]) ]


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
