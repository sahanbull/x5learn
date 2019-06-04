from flask import Flask, jsonify, render_template, request, redirect
from flask_mail import Mail
from flask_security import Security, SQLAlchemySessionUserDatastore, current_user, logout_user, login_required
from flask_security.signals import user_registered
from flask_sqlalchemy import SQLAlchemy
import json
import http.client
from fuzzywuzzy import fuzz
from collections import defaultdict
from random import randint
import urllib
from datetime import datetime, timedelta
from sqlalchemy import or_, and_

# instantiate the user management db classes
from x5learn_server.db.database import get_or_create_session_db
from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET

get_or_create_session_db(DB_ENGINE_URI)

from x5learn_server.db.database import db_session

from x5learn_server.models import UserLogin, Role, User, Enrichment, EnrichmentTask


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

CURRENT_ENRICHMENT_VERSION = 1


# create database when starting the app
@app.before_first_request
def initiate_login_db():
    from x5learn_server.db.database import initiate_login_table_and_admin_profile
    initiate_login_table_and_admin_profile(user_datastore)


@app.route("/")
def home():
    return render_template('home.html')


@app.route("/logout")
# @login_required
def logout():
    logout_user()
    return redirect("/")


@app.route("/search")
def search():
    return render_template('home.html')


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
        resp = get_logged_in_user_profile_and_state()
        if str(get_or_create_logged_in_user().id) == get_guest_id_from_cookie():
            resp.delete_cookie(GUEST_COOKIE_NAME)
        return resp
    return guest_session()


def guest_session():
    user_id = get_guest_id_from_cookie()
    if user_id is None or user_id == '': # No cookie set
        return new_guest_session()
    user = User.query.get(user_id)
    if user is None: # The cookie points to a row which no longer exists
        return new_guest_session()
    return jsonify({'guestUser': {'userState': user.frontend_state}})


def get_guest_id_from_cookie():
    return request.cookies.get(GUEST_COOKIE_NAME)


def new_guest_session():
    user = User()
    db_session.add(user)
    db_session.commit()
    resp = jsonify({'guestUser': {'userState': None}})
    resp.set_cookie(GUEST_COOKIE_NAME, str(user.id))
    return resp


def new_guest_ok():
    user = User()
    db_session.add(user)
    db_session.commit()
    resp = make_response('OK')
    resp.set_cookie(GUEST_COOKIE_NAME, str(user.id))
    return resp


def get_logged_in_user_profile_and_state():
    profile = current_user.user_profile if current_user.user_profile is not None else { 'email': current_user.email }
    user = get_or_create_logged_in_user()
    logged_in_user = {'userState': user.frontend_state, 'userProfile': profile}
    return jsonify({'loggedInUser': logged_in_user})


@user_registered.connect_via(app)
def on_user_registered(sender, user, confirm_token):
    # NB the "user" parameter takes a UserLogin object, not a User object
    # The unfortunate naming results in "user.user" which looks weird although it is technically correct.
    guest = User.query.get(get_guest_id_from_cookie())
    guest.user_login_id = user.id
    user.user = guest
    db_session.commit()


def get_or_create_logged_in_user():
    user = current_user.user
    if user is None: # This will happen for the handful of people who have signed up before this change and have been warned that their user state will be reset. Other than that, there is no good reasons for current_user.user to ever be None. So at a later point, we may want to replace this entire function with simply current_user.user
        user = User()
        db_session.add(user)
        current_user.user = user
        db_session.commit()
    return user


@app.route("/api/v1/save_user_state/", methods=['POST'])
def api_save_user_state():
    frontend_state = request.get_json()
    if current_user.is_authenticated:
        get_or_create_logged_in_user().frontend_state = frontend_state
        db_session.commit()
        return 'OK'
    else:
        user_id = request.cookies.get(GUEST_COOKIE_NAME)
        if user_id == None or user_id == '': # If the user cleared their cookie while using the app
            return new_guest_ok('OK')
        user = User.query.get(user_id)
        if user is None: # In the rare case that the cookie points to no-longer existent row
            return new_guest_ok('OK')
        user.frontend_state = frontend_state
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


@app.route("/api/v1/oers/", methods=['POST'])
def api_oers():
    oers = {}
    for url in request.get_json()['urls']:
        oers[url] = find_oer_by_url(url)
    return jsonify(oers)


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


@app.route("/api/v1/most_urgent_unstarted_enrichment_task/", methods=['POST'])
def most_urgent_unstarted_enrichment_task():
    # task = EnrichmentTask.query.filter_by(started=None).order_by(EnrichmentTask.priority.desc()).first()
    timeout = datetime.now() - timedelta(minutes=10)
    task = EnrichmentTask.query.filter(and_(EnrichmentTask.error == None, or_(EnrichmentTask.started == None, EnrichmentTask.started < timeout))).order_by(EnrichmentTask.priority.desc()).first()
    if task is None: # Queue empty -> Nothing to do
        return jsonify({'info': 'queue empty'})
    url = task.url
    task.started = datetime.now()
    db_session.commit()
    print('Started task with priority:', task.priority, 'url:', url)
    enrichment = Enrichment.query.filter_by(url=url).first()
    if enrichment is None: # shouldn't happen
        error = 'Orphaned EnrichmentTask url: ' + url
        print(error)
        return jsonify({'error': error})
    return jsonify({'data': enrichment.data})


@app.route("/api/v1/ingest_enrichment_data/", methods=['POST'])
def ingest_enrichment_data():
    j = request.get_json(force=True)
    data = j['data']
    url = data['url']
    enrichment = Enrichment.query.filter_by(url=url).first()
    if enrichment is None: # shouldn't normally happen
        return 'Enrichment not found: ' + url
    # Store any new data
    enrichment.data = data
    task = EnrichmentTask.query.filter_by(url=url).first()
    if j['error'] is not None:
        task.error = j['error']
    else:
        enrichment.version = CURRENT_ENRICHMENT_VERSION
        db_session.delete(task)
    db_session.commit()
    return 'OK'


def search_results_from_x5gon_api(text):
    max_results = 18
    encoded_text = urllib.parse.quote(text)
    conn = http.client.HTTPSConnection("platform.x5gon.org")
    conn.request('GET', '/api/v1/search/?url=https://platform.x5gon.org/materialUrl&text='+encoded_text)
    response = conn.getresponse().read().decode("utf-8")
    materials = json.loads(response)['rec_materials'][:max_results]
    enrichments = []
    for index, material in enumerate(materials):
        url = material['url']
        enrichment = Enrichment.query.filter_by(url=url).first()
        if enrichment is None:
            enrichment = Enrichment(url, data_from_x5gon_search_result(material, url))
            db_session.add(enrichment)
            db_session.commit()
        if enrichment.version != CURRENT_ENRICHMENT_VERSION:
            bump_in_queue(url, len(materials)-index)
        enrichments.append(enrichment.data)
    return enrichments


def data_from_x5gon_search_result(material, url):
    # Insert some fields that the frontend expects, using values from the x5gon search result when possible, otherwise default values.
    data = {}
    data['url'] = url
    data['title'] = material['title']
    data['provider'] = material['provider']
    data['description'] = material['description']
    if data['description'] is None:
        data['description'] = ''
    data['date'] = ''
    data['duration'] = ''
    data['images'] = []
    data['wikichunks'] = []
    data['mediatype'] = material['type']
    return data


def bump_in_queue(url, priority):
    task = EnrichmentTask.query.filter_by(url=url).first()
    if task is None:
        task = EnrichmentTask(url, priority)
        db_session.add(task)
    else:
        task.priority += priority
    db_session.commit()


def any_word_matches(words, text):
    for word in words:
        if word in text.lower():
            return True
    return False


def search_suggestions(text):
    all_entity_titles = [] # TODO: use Topics table in db
    matches = [(title, fuzz.partial_ratio(text, title) + fuzz.ratio(text, title)) for title in all_entity_titles]
    matches = sorted(matches, key=lambda k_v: k_v[1], reverse=True)[:20]
    print([v for k, v in matches])
    matches = [k for k, v in matches]
    # import pdb; pdb.set_trace()
    # print(matches)
    return jsonify(matches)


# def search_results_from_experimental_local_oer_data(text):
#     max_results = 18
#     frequencies = defaultdict(int)
#     for video_id, oer in loaded_oers.items():
#         for chunk in oer['wikichunks']:
#             for entity in chunk['entities']:
#                 if text == entity['title'].lower().strip():
#                     frequencies[video_id] += 1
#     # import pdb; pdb.set_trace()
#     results = [loaded_oers[video_id] for video_id, freq in
#                sorted(frequencies.items(), key=lambda k_v: k_v[1], reverse=True)[:max_results]]
#     print(len(results), 'search results found based on wikichunks.')
#     # if len(results) < max_results:
#     #     search_words = text.split()
#     #     n = max_results-len(results)
#     #     print('Search: adding', n,'results by title and description')
#     #     results += [ oer for oer in loaded_oers.values() if any_word_matches(search_words, oer['title']) or any_word_matches(search_words, oer['description']) ][:n]
#     return results


def find_oer_by_url(url):
    enrichment = Enrichment.query.filter_by(url=url).first()
    if enrichment is not None:
        return enrichment.data
    else:
        # Return a blank OER.
        result = {}
        result['date'] = ''
        result['description'] = '(Sorry, this resource is no longer accessible)'
        result['duration'] = ''
        result['images'] = []
        result['provider'] = ''
        result['title'] = '(not found)'
        result['url'] = url
        result['wikichunks'] = []
        result['mediatype'] = 'text'
        return result


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
