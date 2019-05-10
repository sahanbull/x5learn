from flask import Flask, jsonify, render_template, request, redirect
from flask_mail import Mail
from flask_security import Security, SQLAlchemySessionUserDatastore, current_user, logout_user, login_required
from flask_sqlalchemy import SQLAlchemy
import json
import http.client
import sys
import os
import csv
from fuzzywuzzy import fuzz
from collections import defaultdict
from random import randint
import urllib

# instantiate the user management db classes
from x5learn_server.db.database import get_or_create_session_db
from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET

get_or_create_session_db(DB_ENGINE_URI)

from x5learn_server.db.database import db_session

from x5learn_server.models import UserLogin, Role, GuestUser

# Create app
app = Flask(__name__)
mail = Mail()

app.config['DEBUG'] = True
app.config['SECRET_KEY'] = PASSWORD_SECRET
app.config['SECURITY_PASSWORD_HASH'] = "plaintext"

# user registration configs
app.config['SECURITY_REGISTERABLE'] = True
app.config['SECURITY_REGISTER_URL'] = '/signup'
app.config['SECURITY_SEND_REGISTER_EMAIL'] = False

# user password configs
app.config['SECURITY_CHANGEABLE'] = True
app.config['SECURITY_CHANGE_URL'] = '/password_change'
app.config['SECURITY_SEND_PASSWORD_CHANGE_EMAIL'] = False

# Setup Flask-Security
user_datastore = SQLAlchemySessionUserDatastore(db_session,
                                                UserLogin, Role)

# Setup SQLAlchemy
app.config["SQLALCHEMY_DATABASE_URI"] = DB_ENGINE_URI
db = SQLAlchemy(app)

security = Security(app, user_datastore)
mail.init_app(app)


GUEST_COOKIE_NAME = 'x5learn_guest'

# Initial OER data from CSV files
CSV_DATA_DIR = os.environ['X5LEARN_DATA_DIRECTORY']  # e.g. '/home/ucl/x5learn_data/'
loaded_oers = {}
all_entity_titles = set([])

# create database when starting the app
@app.before_first_request
def initiate_login_db():
    from x5learn_server.db.database import initiate_login_table_and_admin_profile
    initiate_login_table_and_admin_profile(user_datastore)
    load_initial_dataset_from_csv()


@app.route("/")
def home():
    return render_template('home.html')


@app.route("/login")
def login():
    return render_template('security/login_user.html')


@app.route("/signup")
def signup():
    return render_template('security/register_user.html')


@app.route("/logout")
# @login_required
def logout():
    logout_user()
    return redirect("/")


@app.route("/search")
def search():
    return render_template('home.html')


# @app.route("/next_steps")
# def next_steps():
#     return render_template('home.html')

# @app.route("/journeys")
# def journeys():
#     return render_template('home.html')

# @app.route("/gains")
# def gains():
#     return render_template('home.html')

@app.route("/notes")
def notes():
    return render_template('home.html')


@app.route("/recent")
def recent():
    return render_template('home.html')


@app.route("/profile")
@login_required
def profile():
    return render_template('home.html')


@app.route("/api/v1/session/", methods=['GET'])
def api_session():
    if current_user.is_authenticated:
        return get_logged_in_user_profile_and_state()
    return get_guest_user_state()


def get_logged_in_user_profile_and_state():
    user = {}
    user['userProfile'] = current_user.user_profile if current_user.user_profile is not None else { 'email': current_user.email }
    user['userState'] = current_user.user_state
    return jsonify({'loggedInUser': user})


def get_guest_user_state():
    guest_user_id = request.cookies.get(GUEST_COOKIE_NAME)
    if guest_user_id == None or guest_user_id == '':
        return create_guest_user_and_save_id_in_cookie(guest_user_response(None))
    else:
        return load_guest_user_state(guest_user_id)


def load_guest_user_state(guest_user_id):
    guest = GuestUser.query.get(guest_user_id)
    if guest is None: # In the rare case that the cookie points to a no-longer existent row
        return create_guest_user_and_save_id_in_cookie(guest_user_response(None))
    else:
        return guest_user_response(guest.user_state)


def create_guest_user_and_save_id_in_cookie(resp):
    guest = GuestUser()
    db_session.add(guest)
    db_session.commit()
    # Passing None will cause Elm to setup the initial user state.
    resp.set_cookie(GUEST_COOKIE_NAME, str(guest.id))
    return resp


def guest_user_response(user_state):
    return jsonify({'guestUser': {'userState': user_state}})


@app.route("/api/v1/save_user_state/", methods=['POST'])
def api_save_user_state():
    user_state = request.get_json()
    if current_user.is_authenticated:
        current_user.user_state = user_state
        db_session.commit()
        return 'OK'
    else:
        guest_user_id = request.cookies.get(GUEST_COOKIE_NAME)
        if guest_user_id == None or guest_user_id == '': # If the user cleared their cookie while using the app
            return create_guest_user_and_save_id_in_cookie('OK')
        guest = GuestUser.query.get(guest_user_id)
        if guest is None: # In the rare case that the cookie points to no-longer existent row
            return create_guest_user_and_save_id_in_cookie('OK')
        guest.user_state = user_state
        db_session.commit()
        return 'OK'


@app.route("/api/v1/search/", methods=['GET'])
def api_search():
    text = request.args['text'].lower().strip()
    results = search_results_from_experimental_local_oer_data(text) + search_results_from_x5gon_api(text)
    return jsonify(results)



@app.route("/api/v1/search_suggestions/", methods=['GET'])
def api_search_suggestions():
    text = request.args['text']
    return search_suggestions(text.lower().strip())


# @app.route("/api/v1/gains/", methods=['GET'])
# def api_gains():
#     return jsonify(dummy_user.gains())


@app.route("/api/v1/oers/", methods=['POST'])
def api_oers():
    urls = request.get_json()['urls']
    oers = {}
    for url in urls:
        oers[url] = find_oer_by_url(url)
    return jsonify(oers)


# @app.route("/api/v1/next_steps/", methods=['GET'])
# def api_next_steps():
#     playlists = dummy_user.recommended_next_steps()
#     return jsonify(playlists)


@app.route("/api/v1/entity_descriptions/", methods=['GET'])
def api_entity_descriptions():
    entity_ids = request.args['ids'].split(',')
    descriptions = {}
    conn = http.client.HTTPSConnection("www.wikidata.org")
    request_string = '/w/api.php?action=wbgetentities&props=descriptions&ids=' + '|'.join(
        entity_ids) + '&languages=en&sitefilter=enwiki&languagefallback=1&format=json'
    conn.request('GET', request_string)
    response = conn.getresponse().read().decode("utf-8")
    j = json.loads(response)
    try:
        entities = j['entities']
        for entity_id, value in entities.items():
            try:
                descriptions[entity_id] = value['descriptions']['en']['value']
            except KeyError:
                # print('WARNING: entity', entity_id, 'has no description.')
                descriptions[entity_id] = '(Description unavailable)'
    except KeyError:
        print('Error trying to retrieve entity descriptions from wikidata. The x5learn_server responded with:')
        print(response)
        print('We sent the following ids:', ','.join(entity_ids))
    return jsonify(descriptions)


@app.route("/api/v1/save_user_profile/", methods=['POST'])
def api_save_user_profile():
    if current_user.is_authenticated:
        current_user.user_profile = request.get_json()
        db_session.commit()
        return 'OK'
    else:
        return 'Error', 403


def load_initial_dataset_from_csv():
    global loaded_oers
    if len(loaded_oers) == 0:
        read_local_oer_data()


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


def search_results_from_x5gon_api(text):
    max_results = 18
    encoded_text = urllib.parse.quote(text)
    conn = http.client.HTTPSConnection("platform.x5gon.org")
    conn.request('GET', '/api/v1/search/?url=https://platform.x5gon.org/materialUrl&text='+encoded_text)
    response = conn.getresponse().read().decode("utf-8")
    # import pdb; pdb.set_trace()
    results = json.loads(response)['rec_materials'][:max_results]
    for result in results:
        result['date'] = ''
        if result['description'] is None:
            result['description'] = ''
        result['duration'] = ''
        result['images'] = []
        result['wikichunks'] = []
        result['mediatype'] = result['type']
    return results


def any_word_matches(words, text):
    for word in words:
        if word in text.lower():
            return True
    return False


def read_local_oer_data():
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
        for oer in csv.DictReader(f, delimiter='\t'):
            url = oer['url']
            if url in loaded_oers:
                continue  # omit duplicates
            if not oer['title']:
                continue  # omit incomplete items
            oer['images'] = json.loads(oer['images'].replace("'", '"'))
            oer['date'] = oer['date'].replace('Published on ', '') if 'date' in oer else ''
            oer['duration'] = human_readable_time_from_ms(float(oer['duration'])) if 'duration' in oer else ''
            del oer['wikichunks']  # Use the new wikifier results instead (from the JSON files).
            del oer[
                'transcript']  # Delete in order to prevent unnecessary network load when serving OER to the frontend.
            oer['mediatype'] = 'video'
            videoid = oer['url'].split('v=')[1].split('&')[0]
            loaded_oers[videoid] = oer
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


def create_fragment(oer_title, start, length):
    oer = find_oer_by_title(oer_title)
    return {'oer': oer, 'start': start, 'length': length}


def create_pathway(rationale, fragments):
    return {'rationale': rationale, 'fragments': fragments}


def find_oer_by_title(title):
    try:
        return [oer for oer in loaded_oers.values() if oer['title'] == title][0]
    except IndexError:
        print('No OER was found with title', title)


def search_suggestions(text):
    matches = [(title, fuzz.partial_ratio(text, title) + fuzz.ratio(text, title)) for title in all_entity_titles]
    matches = sorted(matches, key=lambda k_v: k_v[1], reverse=True)[:20]
    print([v for k, v in matches])
    matches = [k for k, v in matches]
    # import pdb; pdb.set_trace()
    print(matches)
    return jsonify(matches)


def find_oer_by_url(url):
    for oer in loaded_oers.values():
        if oer['url'] == url:
            # print('found', url)
            return oer
    # If not found in the CSV dataset:
    # For now, return a blank oer. TODO: call X5GON API or cache
    oer = {}
    oer['date'] = ''
    oer['description'] = ''
    oer['duration'] = ''
    oer['images'] = []
    oer['provider'] = ''
    oer['title'] = ''
    oer['url'] = url
    oer['wikichunks'] = []
    oer['mediatype'] = 'text'
    return oer


# THUMBNAILS FOR X5GON (experimental)

# def project_folder():
#     return '/Users/stefan/x5/prototypes/60_x5learn_mountains/'

# def image_filename(resource_url):
#     return 'thumbnail_' + re.sub('[^a-zA-Z0-9]', '_', resource_url) + '.jpg'

# def thumbnail_local_path_1(resource_url):
#     return project_folder() + 'assets/img/' + image_filename(resource_url)

# def thumbnail_local_path_2(resource_url):
#     return project_folder() + 'x5learn_server/static/dist/img/' + image_filename(resource_url)

# def thumbnail_url(resource_url):
#     return 'dist/img/' + image_filename(resource_url)


# def create_thumbnail(resource_url):
#     dummy_file_path = project_folder() + 'assets/img/thumbnail_unavailable.jpg'
#     copyfile(dummy_file_path, thumbnail_local_path_1(resource_url))
#     copyfile(dummy_file_path, thumbnail_local_path_2(resource_url))


# @app.route("/<path:anything>")
# def product(anything):
#     return render_template('home.html')

# Adding the following method appears to have fixed an urgent problem that I had encountered in local development:
# sqlalchemy.exc.TimeoutError: QueuePool limit of size 5 overflow 10 reached, connection timed out, timeout 30 (Background on this error at: http://sqlalche.me/e/3o7r)
# The solution was suggested here:
# https://stackoverflow.com/questions/3360951/sql-alchemy-connection-time-out/28040482
# Related question:
# https://stackoverflow.com/questions/24956894/sql-alchemy-queuepool-limit-overflow
# (Not an expert on this - grateful for any clarification)
@app.teardown_appcontext
def shutdown_session(exception=None):
    db_session.remove()


if __name__ == '__main__':
    app.run(debug=True)
