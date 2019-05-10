from flask import Flask, jsonify, render_template, request, redirect
from flask_mail import Mail
from flask_security import Security, SQLAlchemySessionUserDatastore, current_user, logout_user, login_required
from flask_sqlalchemy import SQLAlchemy
import json
import http.client
from fuzzywuzzy import fuzz
from collections import defaultdict
from random import randint
import urllib

# instantiate the user management db classes
from x5learn_server.db.database import get_or_create_session_db
from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET

get_or_create_session_db(DB_ENGINE_URI)

from x5learn_server.db.database import db_session

from x5learn_server.models import UserLogin, Role, GuestUser, Oer

from x5learn_server.db.seed import load_initial_dataset_from_csv

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
    # results = search_results_from_experimental_local_oer_data(text) + search_results_from_x5gon_api(text)
    results = search_results_from_x5gon_api(text)
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
    # TODO
    # q = db_session.query(oers)
    # q.filter(cls.id.in_(
    # q.all()
    # for url in urls:
    #     oers[url] = find_oer_by_url(url)
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


def search_suggestions(text):
    matches = [(title, fuzz.partial_ratio(text, title) + fuzz.ratio(text, title)) for title in all_entity_titles]
    matches = sorted(matches, key=lambda k_v: k_v[1], reverse=True)[:20]
    print([v for k, v in matches])
    matches = [k for k, v in matches]
    # import pdb; pdb.set_trace()
    print(matches)
    return jsonify(matches)


# def find_oer_by_url(url):
#     for oer in loaded_oers.values():
#         if oer['url'] == url:
#             # print('found', url)
#             return oer
#     # If not found in the CSV dataset:
#     # For now, return a blank oer. TODO: call X5GON API or cache
#     oer = {}
#     oer['date'] = ''
#     oer['description'] = '(Sorry, this resource is no longer accessible)'
#     oer['duration'] = ''
#     oer['images'] = []
#     oer['provider'] = ''
#     oer['title'] = '(not found)'
#     oer['url'] = url
#     oer['wikichunks'] = []
#     oer['mediatype'] = 'text'
#     return oer


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
    app.run()
