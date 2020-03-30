from flask import Flask, jsonify, render_template, request, redirect
from flask_mail import Mail, Message
from flask_security import Security, SQLAlchemySessionUserDatastore, current_user, logout_user, login_required
from flask_sqlalchemy import SQLAlchemy
import json
import os  # apologies
import requests
import http.client
import urllib
from collections import defaultdict
from datetime import datetime, timedelta
from dateutil import parser
from sqlalchemy import or_, and_, cast, Integer
from sqlalchemy.orm.attributes import flag_modified
from flask_restplus import Api, Resource, fields, reqparse
import wikipedia

# instantiate the user management db classes
# NOTE WHEN PEP8'ING MODULE IMPORTS WILL MOVE TO THE TOP AND CAUSE EXCEPTION
from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET, MAIL_SENDER, MAIL_USERNAME, MAIL_PASS, MAIL_SERVER, \
    MAIL_PORT, LATEST_API_VERSION, SERVER_NAME
from x5learn_server.db.database import get_or_create_db

_ = get_or_create_db(DB_ENGINE_URI)
from x5learn_server.db.database import db_session
from x5learn_server.models import UserLogin, Role, User, Oer, WikichunkEnrichment, WikichunkEnrichmentTask, \
    EntityDefinition, ResourceFeedback, Action, ActionType, Repository, \
    ActionsRepository, UserRepository, DefinitionsRepository, Course, UiLogBatch, Note, Playlist, Playlist_Item, \
    Temp_Playlist, License, TempPlaylistRepository

from x5learn_server.enrichment_tasks import push_enrichment_task_if_needed, push_enrichment_task, save_enrichment
from x5learn_server.lab_study import frozen_search_results_for_lab_study, is_special_search_key_for_lab_study
from x5learn_server.course_optimization import optimize_course

# Create app
app = Flask(__name__)
mail = Mail()

app.config['SERVER_NAME'] = SERVER_NAME
app.config['DEBUG'] = False
app.config['SECRET_KEY'] = PASSWORD_SECRET
app.config['SECURITY_PASSWORD_HASH'] = "bcrypt"
app.config['SECURITY_PASSWORD_SALT'] = PASSWORD_SECRET

# user registration configs
app.config['SECURITY_REGISTERABLE'] = True
app.config['SECURITY_REGISTER_URL'] = '/signup'
app.config['SECURITY_SEND_REGISTER_EMAIL'] = True
app.config['SECURITY_CONFIRMABLE'] = True
app.config['SECURITY_POST_REGISTER_VIEW'] = '/login'

# user password configs
app.config['SECURITY_CHANGEABLE'] = True
app.config['SECURITY_CHANGE_URL'] = '/password_change'
app.config['SECURITY_EMAIL_SENDER'] = MAIL_SENDER
app.config['SECURITY_SEND_PASSWORD_CHANGE_EMAIL'] = True
app.config['SECURITY_RECOVERABLE'] = True
app.config['SECURITY_RESET_URL'] = '/recover'

# Setup Flask-Security
user_datastore = SQLAlchemySessionUserDatastore(db_session,
                                                UserLogin, Role)

# Setup SQLAlchemy
app.config["SQLALCHEMY_DATABASE_URI"] = DB_ENGINE_URI
db = SQLAlchemy(app)

security = Security(app, user_datastore)

# Setup Flask-Mail Server
app.config['MAIL_SERVER'] = MAIL_SERVER
app.config['MAIL_PORT'] = MAIL_PORT
app.config['MAIL_USE_SSL'] = True
app.config['MAIL_USERNAME'] = MAIL_USERNAME
app.config['MAIL_PASSWORD'] = MAIL_PASS
app.config['MAIL_DEFAULT_SENDER'] = MAIL_SENDER

mail.init_app(app)

CURRENT_ENRICHMENT_VERSION = 1
MAX_SEARCH_RESULTS = 18  # number divisible by 2 and 3 to fit nicely into grid
USE_RECOMMENDATIONS_FROM_LAM = True  # if true, uses the new solution see #290
SUPPORTED_VIDEO_FORMATS = ['video', 'mp4', 'mov', 'webm', 'ogg']
SUPPORTED_FILE_FORMATS = SUPPORTED_VIDEO_FORMATS + ['pdf']

# defaults license
_DEFAULT_LICENSE = 1

PLAYLIST_PREFIX = "pl:"

# Number of seconds between actions that report the ongoing video play position.
# Keep this constant in sync with videoPlayReportingInterval on the frontend!
VIDEO_PLAY_REPORTING_INTERVAL = 10


# create database when starting the app
@app.before_first_request
def initiate_login_db():
    from x5learn_server.db.database import initiate_login_table_and_admin_profile
    initiate_login_table_and_admin_profile(user_datastore)
    initiate_action_types_table()
    # cleanup_enrichment_errors()


def cleanup_enrichment_errors():
    WIKIFIER_BLACKLIST = ['Forward (association football)', 'RenderX', 'MEDLINE', 'Medline', 'MedLine', 'medline',
                          'MEDLAR']
    print('\nin cleanup_enrichment_errors')
    enrichments = WikichunkEnrichment.query.all()
    for enrichment in enrichments:
        for chunk in enrichment.data['chunks']:
            filtered_entities = [entity for entity in chunk['entities'] if entity['title'] not in WIKIFIER_BLACKLIST]
        if filtered_entities != chunk['entities']:
            print(chunk['entities'])
            print(filtered_entities)
            chunk['entities'] = filtered_entities
            flag_modified(enrichment, 'data')
            db_session.commit()
    print('done.\n')


# Setting wikipedia api language
wikipedia.set_lang("en")

# Creating a repository for accessing database
repository = Repository()


# @app.route("/make_users_for_webinar/")
# def make_users_for_webinar():
#     # import pdb; pdb.set_trace()
#     for index in range(40):
#         user = UserLogin()
#         user.email = 'p'+str(index+1)
#         user.password = 'study'
#         user.active = True
#         user.confirmed_at = datetime.utcnow();
#         db.session.add(user)
#         db.session.commit()
#     # for name in 'davor john colin stefan'.split(' '):
#     #     user = UserLogin()
#     #     user.email = name
#     #     user.password = 'japan'
#     #     user.active = True
#     #     user.confirmed_at = datetime.utcnow();
#     #     db.session.add(user)
#     #     db.session.commit()
#     return render_template('home.html')


@app.route("/")
def home():
    if current_user.is_authenticated:
        return render_template('home.html')
    else:
        return render_template('about.html')


@app.route("/about")
def about():
    return render_template('about.html')


@app.route("/logout")
# @login_required
def logout():
    logout_user()
    return redirect("/")


@app.route("/featured")
def featured():
    return render_template('home.html')


@app.route("/search")
def search():
    return render_template('home.html')


@app.route("/resource/<oer_id>")
def resource(oer_id):
    return render_template('home.html')


@app.route("/profile")
@login_required
def profile():
    return render_template('home.html')


@app.route("/publish_playlist")
@login_required
def playlist():
    return render_template('home.html')


@app.route("/api/v1/session/", methods=['GET'])
def api_session():
    if current_user.is_authenticated:
        resp = get_logged_in_user_profile_and_state()
        return resp
    return jsonify({'guestUser': 'OK'})


def get_logged_in_user_profile_and_state():
    profile = current_user.user_profile if current_user.user_profile is not None else {
        'email': current_user.email}
    logged_in_user = {'userProfile': profile, 'isContentFlowEnabled': is_contentflow_enabled(),
                      'overviewTypeId': get_overview_type_setting()}
    return jsonify({'loggedInUser': logged_in_user})


# Look at actions to determine whether ContentFlow is enabled or disabled
def is_contentflow_enabled():
    action = Action.query.filter(Action.user_login_id == current_user.get_id(),
                                 Action.action_type_id.in_([7])).order_by(Action.id.desc()).first()
    return True if action is None else action.params['enable']


# Look at actions to determine the OverviewType setting
def get_overview_type_setting():
    action = Action.query.filter(Action.user_login_id == current_user.get_id(),
                                 Action.action_type_id.in_([10])).order_by(Action.id.desc()).first()
    return 'thumbnail' if action is None else action.params['selectedMode']


# @user_registered.connect_via(app)
# def on_user_registered(sender, user, confirm_token):
#     ...


# def get_or_create_logged_in_user():
#     user = current_user.user
#     if user is None:
#         user = User()
#         db_session.add(user)
#         current_user.user = user
#         db_session.commit()
#     return user


@app.route("/api/v1/recommendations/", methods=['GET'])
def api_recommendations():
    oer_id = int(request.args['oerId'])
    if USE_RECOMMENDATIONS_FROM_LAM:
        oers = recommendations_from_lam_api(oer_id)  # new
    else:
        oers = recommendations_from_wikichunk_enrichments(oer_id)  # old
    for oer in oers:
        print(oer.id, oer.data['material_id'])
    # TODO: save as new action 'ContentRecommendations'
    return jsonify([oer.data_and_id() for oer in oers])


def get_items_in_playlist(playlist_id):
    """ this function gets the list of items in a playlist

    Args:
        playlist_id (int): playlist id

    Returns:
        [Oer]: list of OER materials in the sequence they appear in the playlist
    """
    # TODO: this function has to be implemented !!!
    return []


@app.route("/api/v1/search/", methods=['GET'])
def api_search():
    """
    API endpoint for search.

    Receives multiple arguments in the payload such as "text", ...
    Returns:

    """
    text = request.args['text'].lower().strip()
    if text.startswith(PLAYLIST_PREFIX):  # if its a playlist
        playlist_id = int(text[3:])

        # get the list of items
        results = get_items_in_playlist(playlist_id)
    try:
        # if the text is a number, retrieve the oer with that oer_id
        oer_id = int(text)
        oer = Oer.query.get(oer_id)
        results = [] if oer is None else [oer]
    except ValueError:
        results = search_results_from_x5gon_api(text)
    return jsonify([oer.data_and_id() for oer in results])


@app.route("/api/v1/oers/", methods=['POST'])
def api_oers():
    oers = [find_oer_by_id(oer_id) for oer_id in request.get_json()['ids']]
    return jsonify(oers)


@app.route("/api/v1/video_usages/", methods=['GET'])
def api_video_usages():
    actions = Action.query.filter(Action.user_login_id == current_user.get_id(),
                                  Action.action_type_id.in_([4, 5, 6, 9])).order_by(Action.id).all()
    positions_per_oer = defaultdict(list)
    for action in actions:
        oer_id = str(action.params['oerId'])
        position = action.params['positionInSeconds']
        positions_per_oer[oer_id].append(position)
    ranges_per_oer = defaultdict(list)
    for oer_id, positions in positions_per_oer.items():
        ranges_per_oer[oer_id] = video_usage_ranges_from_positions(positions)
    return jsonify(ranges_per_oer)


@app.route("/api/v1/course_optimization/", methods=['POST'])
def api_course_optimization():
    old_oer_ids = request.get_json()['oerIds']
    new_oer_ids = optimize_course(old_oer_ids)
    return jsonify(new_oer_ids)


@app.route("/api/v1/load_course/", methods=['POST'])
def api_load_course():
    course = Course.query.filter(Course.user_login_id == current_user.get_id()).order_by(Course.id.desc()).first()
    if course is None:
        user_login_id = current_user.get_id()  # Assuming that guests cannot use this feature
        course = Course(user_login_id, {'items': []})
    else:
        # remove OERs that don't exist anymore
        course.data['items'] = [item for item in course.data['items'] if Oer.query.get(item['oerId']) is not None]
    return jsonify(course.data)


@app.route("/api/v1/save_course/", methods=['POST'])
def api_save_course():
    items = request.get_json()['items']
    user_login_id = current_user.get_id()  # Assuming that guests cannot use this feature
    course = Course(user_login_id, {'items': items})
    db_session.add(course)
    db_session.commit()
    return 'OK'


@app.route("/api/v1/save_ui_logged_events_batch/", methods=['POST'])
def api_save_ui_logged_events_batch():
    client_time = request.get_json()['clientTime']
    text = request.get_json()['text']
    user_login_id = current_user.get_id()  # Assuming that guests cannot use this feature
    batch = UiLogBatch(user_login_id, client_time, text)
    db_session.add(batch)
    db_session.commit()
    return 'OK'


def video_usage_ranges_from_positions(positions):
    ranges = []
    positions = sorted(positions)
    for index, position in enumerate(positions):
        if index > 0 and position >= ranges[-1]['start'] and position < ranges[-1]['start'] + ranges[-1][
            'length'] + VIDEO_PLAY_REPORTING_INTERVAL:
            # extend the last range
            ranges[-1]['length'] = position - ranges[-1]['start'] + VIDEO_PLAY_REPORTING_INTERVAL
        else:
            # add a new range
            ranges.append({'start': position, 'length': VIDEO_PLAY_REPORTING_INTERVAL})
    return ranges


@app.route("/api/v1/featured/", methods=['GET'])
def api_featured():
    urls = ['http://hydro.ijs.si/v015/f9/7gh3dwpzrfpfvxnrl5fkaq4nedrqguh6.mp4',
            'http://hydro.ijs.si/v00b/8c/rsctlkzcht24mvake5k3cyjkbtfvr22b.mp4',
            'http://hydro.ijs.si/v001/46/i3fx77camctxek5oqnpt7hjfflfpezor.mp4']
    oers = [oer.data_and_id() for oer in Oer.query.filter(Oer.url.in_(urls)).order_by(Oer.url.desc()).all()]
    return jsonify(oers)


@app.route("/api/v1/resource_feedback/", methods=['POST'])  # to be replaced by Actions API
def api_resource_feedback():
    oer_id = request.get_json()['oerId']
    text = request.get_json()['text']
    user_login_id = current_user.get_id()  # Assuming we are never going to allow feedback from logged-out users
    feedback = ResourceFeedback(user_login_id, oer_id, text)
    db_session.add(feedback)
    db_session.commit()
    return 'OK'


@app.route("/api/v1/save_user_profile/", methods=['POST'])
def api_save_user_profile():
    if current_user.is_authenticated:
        current_user.user_profile = request.get_json()
        db_session.commit()
        return 'OK'
    else:
        return 'Error', 403


@app.route("/api/v1/wikichunk_enrichments/", methods=['POST'])
def api_wikichunk_enrichments():
    enrichments = []
    for oer_id in request.get_json()['ids']:
        enrichment = find_enrichment_by_oer_id(oer_id)
        if enrichment is not None:
            enrichments.append(enrichment.data)
        else:
            oer = Oer.query.get(oer_id)
            if oer is not None:
                push_enrichment_task(oer.url, 1)
    return jsonify(enrichments)


@app.route("/api/v1/most_urgent_unstarted_enrichment_task/", methods=['POST'])
def most_urgent_unstarted_enrichment_task():
    timeout = datetime.now() - timedelta(minutes=10)
    task = WikichunkEnrichmentTask.query.filter(and_(WikichunkEnrichmentTask.error == None, or_(
        WikichunkEnrichmentTask.started == None, WikichunkEnrichmentTask.started < timeout))).order_by(
        WikichunkEnrichmentTask.priority.desc()).first()
    if task is None:
        return jsonify({'info': 'No tasks available'})
    url = task.url
    print('Starting task with priority:', task.priority, 'url:', url)
    task.started = datetime.now()
    task.priority = 0
    db_session.commit()
    oer = Oer.query.filter_by(url=url).first()
    if oer is None:
        msg = 'Missing OER: ' + str(url)
        print(msg)
        return jsonify({'info': msg})
    return jsonify({'data': oer.data})


@app.route("/api/v1/ingest_wikichunk_enrichment/", methods=['POST'])
def ingest_wikichunk_enrichment():
    j = request.get_json(force=True)
    error = j['error']
    data = j['data']
    url = j['url']
    print('ingest_wikichunk_enrichment', url)

    old_enrichment = WikichunkEnrichment.query.filter_by(url=url).first()
    if old_enrichment is not None:
        db_session.delete(old_enrichment)

    task = WikichunkEnrichmentTask.query.filter_by(url=url).first()
    if error is not None:
        task.error = error
    elif task is not None:
        db_session.delete(task)
    db_session.commit()
    save_enrichment(url, data)

    save_definitions(data)

    return 'OK'


@app.route("/api/v1/ingest_oer/", methods=['POST'])
def ingest_oer():
    j = request.get_json(force=True)
    material_id = j['material_id']
    print('ingest_oer', material_id)
    return do_ingest_oer(material_id)


def do_ingest_oer(material_id):
    oer = find_oer_by_material_id(material_id)
    if oer is not None:
        return jsonify({'ok': 'Oer with material_id {} EXISTS. URL = {}'.format(material_id, oer.url)})
    conn = http.client.HTTPSConnection("platform.x5gon.org")
    conn.request('GET', '/api/v1/oer_materials/' + str(material_id))
    response = conn.getresponse()
    if response.status != 200:
        return jsonify({'error': 'Oer with material_id {} FAILED with status code {}. Reason: {}'.format(material_id,
                                                                                                         response.status,
                                                                                                         response.reason)})
    body = response.read().decode("utf-8")
    material = json.loads(body)['oer_materials']
    url = material['url']
    oer = Oer(url, convert_x5_material_to_oer_data(material))
    db_session.add(oer)
    db_session.commit()
    push_enrichment_task(url, 1)
    return jsonify(
        {'ok': 'Oer with material_id {} CREATED. Enrichment task started. URL = {}'.format(material_id, url)})


@app.route("/api/v1/entity_definitions/", methods=['GET'])
def api_entity_descriptions():
    entity_ids = request.args['ids'].split(',')
    definitions = {}
    for entity_id in entity_ids:
        entity_definition = EntityDefinition.query.filter_by(
            entity_id=entity_id).first()
        definitions[entity_id] = entity_definition.extract if entity_definition is not None else ''
    return jsonify(definitions)


def search_results_from_x5gon_api(text):
    text = urllib.parse.quote(text)
    if is_special_search_key_for_lab_study(text):
        return frozen_search_results_for_lab_study(text)
    return search_results_from_x5gon_api_pages(text, 1, [])


# This function is called recursively
# until the number of search results hits a certain minimum or stops increasing
def search_results_from_x5gon_api_pages(text, page_number, oers):
    # print('X5GON search page_number', page_number)
    conn = http.client.HTTPSConnection("platform.x5gon.org")
    conn.request(
        'GET', '/api/v1/search/?url=https://platform.x5gon.org/materialUrl&type=all&text=' + text + '&page=' + str(
            page_number))
    response = conn.getresponse().read().decode("utf-8")
    metadata = json.loads(response)['metadata']
    materials = json.loads(response)['rec_materials']
    materials = filter_x5gon_search_results(materials)
    # materials = remove_duplicates_from_x5gon_search_results(materials)
    for index, material in enumerate(materials):
        url = material['url']
        # Some urls that were longer than 255 caused errors.
        # TODO: change the type of all url colums from String(255) to Text()
        # Temporary fix: ignore search results with very long urls
        if len(url) > 255:
            continue
        material = fetch_captions_from_x5gon_api(material)
        oer = retrieve_oer_or_create_from_x5gon_material(material)
        push_enrichment_task(url, int(1000 / (index + 1)) + 1)
        oers.append(oer)
    oers = oers[:MAX_SEARCH_RESULTS]
    # exits the search if exceeds the last page returned from the api
    if page_number > metadata['total_pages']:
        return oers
    if len(oers) >= MAX_SEARCH_RESULTS:
        return oers
    return search_results_from_x5gon_api_pages(text, page_number + 1, oers)


def retrieve_oer_or_create_from_x5gon_material(material):
    url = material['url']
    oer = Oer.query.filter_by(url=url).first()
    if oer is None:
        oer = Oer(url, convert_x5_material_to_oer_data(material))
        db_session.add(oer)
        db_session.commit()
    # Fix a problem with videolectures lacking duration info
    if oer.data['mediatype'] in SUPPORTED_VIDEO_FORMATS and oer.data['duration'] == '' and (
            'durationInSeconds' not in oer.data):
        oer = inject_duration(oer)
    # Fix provider dict replaced with a string as expected by Elm
    if isinstance(oer.data['provider'], dict):
        new_data = json.loads(json.dumps(oer.data))
        new_data['provider'] = new_data.get('provider', {}).get('name', ' - ')
        oer.data = new_data
    elif not isinstance(oer.data['provider'], str):
        new_data = json.loads(json.dumps(oer.data))
        new_data['provider'] = " - "
        oer.data = new_data
    push_enrichment_task_if_needed(url, 1)
    return oer


def inject_duration(oer):
    seconds = os.popen(
        'ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 ' + oer.url).read().strip()
    seconds = int(float(seconds))
    duration = str(int(seconds / 60)) + ':' + str(seconds % 60).zfill(2)
    print('inject_duration: ', duration)
    new_data = json.loads(json.dumps(oer.data))  # https://stackoverflow.com/a/53977819/2237986
    new_data['durationInSeconds'] = seconds
    new_data['duration'] = duration
    oer.data = new_data
    db_session.commit()
    return oer


def filter_x5gon_search_results(materials):
    # (un)comment the lines below to enable/disable filters as desired

    # include videos only
    # TODO: remove the only video constrain but also make sure the pdf filters are back online
    materials = [m for m in materials if is_video(m['url'])]

    # exclude youtube videos
    materials = [m for m in materials if 'youtu' not in m['url']]

    # filter by file suffix
    # materials = [m for m in materials if m['url'].endswith(
    #     '.pdf') or is_video(m['url'])]

    # TODO: --- pdf filters found below ---
    # crudely filter out materials from MIT OCW that are assignments or date back to the 90s or early 2000s
    # materials = [m for m in materials if '/assignments/' not in m['url']
    #              and '199' not in m['url'] and '200' not in m['url']]

    # Exclude non-english materials because they tend to come out poorly after wikification. X5GON search doesn't have a language parameter at the time of writing.
    # materials = [m for m in materials if m['language'] == 'en']
    return materials


# def remove_duplicates_from_x5gon_search_results(materials):
#     enrichments = {}
#     urls = [m['url'] for m in materials]
#     for enrichment in WikichunkEnrichment.query.filter(WikichunkEnrichment.url.in_(urls)).all():
#         enrichments[enrichment.url] = enrichment
#     included_materials = []
#     included_enrichments = []

#     def is_duplicate(material):
#         url = material['url']
#         # For materials that haven't been enriched yet, we can't tell whether they are identical.
#         if url not in enrichments:
#             return False
#         enrichment = enrichments[url]
#         for e in included_enrichments:
#             if fuzz.ratio(e.entities_to_string(), enrichment.entities_to_string()) > 90:
#                 return True
#         return False

#     for m in materials:
#         if not is_duplicate(m):
#             included_materials.append(m)
#             url = m['url']
#             if url in enrichments:
#                 included_enrichments.append(enrichments[url])
#     return included_materials


def convert_x5_material_to_oer_data(material):
    # Insert some fields that the frontend expects, using values from the x5gon search result when possible, otherwise default values.
    data = {}
    data['url'] = material['url']
    data['material_id'] = material['material_id']
    data['title'] = material['title'] or '(Title unavailable)'

    provider = material['provider'] or ''
    if 'provider_name' in provider:  # sometimes provider comes as a dict
        provider = provider['provider_name']
    data['provider'] = provider

    data['description'] = material['description'] or ''

    data['date'] = ''
    if 'creation_date' in material:
        try:
            data['date'] = parser.parse(material['creation_date']).strftime("%Y-%m-%d")
        except Exception:
            pass

    data['duration'] = ''
    data['images'] = []
    data['mediatype'] = material['type']
    data['translations'] = material['translations']

    return data


def fetch_captions_from_x5gon_api(material):
    oer_translations_endpoint = "/oer_materials/{}/contents?extension=webvtt"
    contents = requests.get(
        "https://platform.x5gon.org/api/v1" + oer_translations_endpoint.format(material['material_id'])).json()

    material['translations'] = {}
    for content in contents['oer_contents']:
        # api does not seem to filter webvtt yet so doing it manually
        if content['extension'] != 'webvtt':
            continue
        material['translations'][content['language']] = content.get('value', '').get('value', '')

    return material


def save_definitions(data):
    definitions = set([])
    for chunk in data['chunks']:
        for entity in chunk['entities']:
            title = entity['title']
            # print(title, '...')
            definition = EntityDefinition.query.filter_by(title=title).first()
            if definition is None and definition not in definitions:
                encoded_title = urllib.parse.quote(title)
                # Request definitions from wikipedia.
                # This should probably happen in the enrichment worker
                # rather than the flask app for at least three reasons:
                # 1. keeping requests times short
                # 2. better error handling
                # 3. guaranteeing that definitions are available together with enrichment
                conn = http.client.HTTPSConnection('en.wikipedia.org')
                conn.request(
                    'GET',
                    '/w/api.php?action=query&prop=extracts&exintro&explaintext&exsentences=1&titles=' + encoded_title + '&format=json')
                response = conn.getresponse().read().decode("utf-8")
                pages = json.loads(response)['query']['pages']
                (_, page) = pages.popitem()
                if 'extract' not in page:
                    print('Could not save definition for', title)
                    return
                extract = page['extract']
                # print(extract)
                definition = EntityDefinition(
                    entity['id'], title, entity['url'], extract, lang='en')
                definitions.add(definition)
    for definition in definitions:
        db_session.add(definition)
        db_session.commit()


def find_oer_by_id(oer_id):
    oer = Oer.query.get(oer_id)
    if oer is not None:
        return oer.data_and_id()
    else:
        # Return a blank OER. This should not happen normally
        print('Missing OER with id', oer_id)
        oer = {}
        oer['id'] = oer_id
        oer['date'] = ''
        oer['description'] = '(Sorry, this resource is no longer accessible)'
        oer['duration'] = ''
        oer['images'] = []
        oer['provider'] = ''
        oer['title'] = '(not found)'
        oer['url'] = ''
        oer['mediatype'] = 'text'
        return oer


def is_video(url):
    url = url.lower()
    return url.endswith('.mp4') or url.endswith('.webm') or url.endswith('.ogg')


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
#  (Not an expert on this - grateful for any clarification)
@app.teardown_appcontext
def shutdown_session(exception=None):
    db_session.remove()


# Defining api for X5Learn to access various resources
api = Api(app, title='X5Learn API', version=LATEST_API_VERSION, doc='/apidoc/',
          description='An API to access resources related to X5Learn web application')

ns_info = api.namespace(
    'api/latest/info', description='Information relating to the API')


@ns_info.route('/')
class APIInfo(Resource):
    def get(self):
        return {'version': LATEST_API_VERSION,
                'currency': 'latest',
                'status': 'under development'}


# Defining actions resource for API access
ns_action = api.namespace('api/v1/action', description='Actions')

m_action = api.model('Action', {
    'action_type_id': fields.Integer(required=False, description='The action type id for the action'),
    'params': fields.String(required=False, description='A json object with params related to the action'),
    'is_bundled': fields.Boolean(default=False, required=True,
                                 description='Boolean flag to differentiate between a single entry or a bundle entry'),
    'action_type_ids': fields.List(fields.Integer, required=False, description='A list of action type ids'),
    'params_list': fields.List(fields.String, required=False,
                               description='Params list for corresponding action type ids')
})


@ns_action.route('/')
class ActionList(Resource):
    '''Shows a list of all actions, and lets you POST to add new actions'''

    @ns_action.doc('list_actions', params={'action_type_id': 'Filter result set by action type id (Default: None)',
                                           'with_oer_id_only': 'Fetch actions only with material id (Default: false)',
                                           'sort': 'Sort result set by timestamp (Default: desc)',
                                           'offset': 'Offset result set by the given number (Default: 0)',
                                           'limit': 'Limit result set to a specific number of records (Default: None)'})
    def get(self):
        '''Fetches multiple actions from database based on params'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401
        else:
            # Declaring and processing params available for request
            parser = reqparse.RequestParser()
            parser.add_argument('action_type_id', type=int)
            parser.add_argument('sort', default='desc', choices=(
                'asc', 'desc'), help='Bad choice')
            parser.add_argument('with_oer_id_only', default='false', choices=(
                'true', 'false'), help='Bad choice')
            parser.add_argument('offset', default=0, type=int)
            parser.add_argument('limit', default=None, type=int)
            args = parser.parse_args()

            # Creating a actions repository for unique data fetch
            actions_repository = ActionsRepository()
            result_list = actions_repository.get_actions(current_user.get_id(), args['action_type_id'], args['sort'],
                                                         args['offset'], args['limit'])

            # Eliminating actions without a material id
            to_be_removed = list()
            if args['with_oer_id_only'] == "true":
                for i in result_list:
                    if not i.Action.params:
                        to_be_removed.append(i)
                    else:
                        temp_list = i.Action.params
                        if 'oer_id' not in temp_list:
                            to_be_removed.append(i)

            if to_be_removed:
                for i in to_be_removed:
                    result_list.remove(i)

            # Converting result list to JSON friendly format
            serializable_list = list()
            if (result_list):
                for i in result_list:
                    tempObject = i.Action.serialize
                    tempObject['action_type'] = i.ActionType.description

                    temp_list = i.Action.params
                    if 'oer_id' in temp_list:
                        temp_oer = repository.get_by_id(Oer, temp_list['oer_id'])
                        if temp_oer.data:
                            if 'title' in temp_oer.data:
                                tempObject['params']['title'] = temp_oer.data['title']

                    serializable_list.append(tempObject)

            return serializable_list

    @ns_action.doc('log_action', validate=True)
    @ns_action.expect(m_action)
    def post(self):
        '''Log action to database'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        if api.payload['is_bundled']:
            if len(api.payload['action_type_ids']) != len(api.payload['params_list']):
                return {'result': 'One or more arguments were found missing.'}, 400
            count = 0
            for idx, val in enumerate(api.payload['action_type_ids']):
                action = Action(val, json.loads(
                    api.payload['params_list'][idx]), current_user.get_id())
                repository.add(action)
                count = count + 1
            return {'result': 'Actions logged. No of Actions - {}'.format(count)}, 201
        else:
            if not api.payload['action_type_id']:
                return {'result': 'Action type id is required'}, 400
            else:
                action = Action(api.payload['action_type_id'], json.loads(
                    api.payload['params']), current_user.get_id())
                repository.add(action)
                return {'result': 'Action logged'}, 201


# Defining user resource for API access
ns_user = api.namespace('api/v1/user', description='User')


@ns_user.route('/forget')
class UserApi(Resource):
    '''Api to manage user'''

    def delete(self):
        '''Delete user actions and user'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401
        else:
            id = current_user.get_id()
            user = repository.get_by_id(UserLogin, id)

            # Creating a user repository for unique action
            user_repository = UserRepository()
            _ = user_repository.forget_user(user, id)

            # Sending confirmation mail
            if user.email:
                try:
                    msg = Message("x5Learn Account Deleted", sender=MAIL_SENDER, recipients=[user.email])
                    msg.body = "Your account and related data has been deleted."
                    msg.html = render_template('/security/email/base_message.html', user=user, app_name=MAIL_SENDER,
                                               message=msg.body)
                    mail.send(msg)
                except Exception:
                    return {'result': 'Mail server not configured'}, 400

            return {'result': 'User deleted'}, 200


@ns_user.route('/history')
class UserHistoryApi(Resource):
    '''Api to fetch user history'''

    def get(self):
        '''Get user history'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        # Creating a actions repository for unique data fetch
        actions_repository = ActionsRepository()
        result_list = actions_repository.get_actions(current_user.get_id(), 1, 'desc', 0, 20)

        # Extracting oer ids
        oers = list()
        if result_list is not None:
            for i in result_list:
                temp_action = i.Action.serialize
                oer_details = repository.get_by_id(Oer, temp_action['params'].get('oerId', 0))

                oers.append({
                    'oer_id': temp_action['params'].get('oerId', 0),
                    'last_accessed': temp_action['created_at'],
                    'title': oer_details.data.get('title', ' - ')
                })

        return {'oers': oers}, 200


# Defining user resource for API access
ns_definition = api.namespace('api/v1/definition', description='Definitions')

m_definition = api.model("Definition",
                         {'titles': fields.String(description="Titles", required=True, help="List of titles as JSON")})


@ns_definition.route('/')
class Definition(Resource):
    '''Api to get definitions of given titles from wikipedia'''

    @ns_definition.doc('get_definition')
    @ns_definition.expect(m_definition)
    def post(self):
        '''Get definition for a single or list of titles'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        # Declaring and processing params available for request
        args = request.json

        if 'titles' not in args:
            return {'result': 'Titles are required'}, 400

        titles = json.loads(args['titles'])

        if not titles:
            return {'result': 'Titles are required'}, 400

        # Creating a definitions repository for unique action
        definitions_repository = DefinitionsRepository()
        temp_db_defs = definitions_repository.get_definitions_list(titles)

        temp_db_lookup = dict()
        if temp_db_defs:
            for i in temp_db_defs:
                temp_db_lookup[i.title] = i

        result = list()
        if titles:
            for i in titles:

                if i in temp_db_lookup:
                    result.append({
                        'title': temp_db_lookup[i].title,
                        'definition': temp_db_lookup[i].extract,
                        'url': temp_db_lookup[i].url
                    })
                    continue

                try:
                    # Fetching missing definitions from wikipedia api
                    temp_wiki_page = wikipedia.page(i)
                    temp_wiki_def = wikipedia.summary(temp_wiki_page.title, 1, None, True)
                    result.append({
                        'title': temp_wiki_page.title,
                        'definition': temp_wiki_def,
                        'url': temp_wiki_page.url
                    })

                    # Saving fetched data for next time
                    entity_def = EntityDefinition(temp_wiki_page.pageid, i, temp_wiki_page.url, temp_wiki_def, "en")
                    repository.add(entity_def)

                except (wikipedia.exceptions.PageError, wikipedia.exceptions.DisambiguationError):
                    result.append({
                        'title': i,
                        'definition': None,
                        'url': None
                    })

        return result, 200


# Defining notes resource for API access
ns_notes = api.namespace('api/v1/note', description='Notes')

m_note = api.model('Note', {
    'oer_id': fields.String(required=True, max_length=255, description='The material id of the note associated with'),
    'text': fields.String(required=True, description='The content of the note')
})


@ns_notes.route('/')
class NotesList(Resource):
    '''Shows a list of all notes, and lets you POST to add new notes'''

    @ns_notes.doc('list_notes', params={'oer_id': 'Filter by material id',
                                        'sort': 'Sort results (Default: desc)',
                                        'offset': 'Offset results',
                                        'limit': 'Limit results'})
    def get(self):
        '''Fetches multiple notes from database based on params'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401
        else:
            # Declaring and processing params available for request
            parser = reqparse.RequestParser()
            parser.add_argument('oer_id', type=int)
            parser.add_argument('sort', default='desc', choices=('asc', 'desc'), help='Bad choice')
            parser.add_argument('offset', type=int)
            parser.add_argument('limit', type=int)
            args = parser.parse_args()

            # Building and executing query object
            query_object = db_session.query(Note)

            if (args['oer_id']):
                query_object = query_object.filter(Note.oer_id == args['oer_id'])

            query_object = query_object.filter(Note.user_login_id == current_user.get_id())
            query_object = query_object.filter(Note.is_deactivated == False)

            if (args['sort'] == 'desc'):
                query_object = query_object.order_by(Note.created_at.desc())
            else:
                query_object = query_object.order_by(Note.created_at.asc())

            if (args['offset']):
                query_object = query_object.offset(args['offset'])

            if (args['limit']):
                query_object = query_object.limit(args['limit'])

            result_list = query_object.all()

            # Converting result list to JSON friendly format
            serializable_list = list()
            if (result_list):
                serializable_list = [i.serialize for i in result_list]

            return serializable_list

    @ns_notes.doc('create_note')
    @ns_notes.expect(m_note, validate=True)
    def post(self):
        '''Creates a new note in database'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401
        elif not api.payload['text'] or not api.payload['oer_id']:
            return {'result': 'Material id and text params cannot be empty'}, 400
        else:
            note = Note(api.payload['oer_id'], api.payload['text'], current_user.get_id(), False)
            db_session.add(note)
            db_session.commit()
            return {'result': 'Note added'}, 201


@ns_notes.route('/<int:id>')
@ns_notes.response(404, 'Note not found')
@ns_notes.param('id', 'The note identifier')
class Notes(Resource):
    '''Show a single note item and lets you update or delete them'''

    @ns_notes.doc('get_note')
    def get(self, id):
        '''Fetch requested note from database'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        query_object = db_session.query(Note)
        query_object = query_object.filter(Note.id == id)
        query_object = query_object.filter(Note.user_login_id == current_user.get_id())
        query_object = query_object.filter(Note.is_deactivated == False)
        note = query_object.one_or_none()

        if not note:
            return {}, 400

        return note.serialize, 200

    @ns_notes.doc('update_note', params={'text': 'Text to update'})
    def put(self, id):
        '''Update selected note'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        # Declaring and processing params available for request
        parser = reqparse.RequestParser()
        parser.add_argument('text', required=True)
        args = parser.parse_args()

        query_object = db_session.query(Note)
        query_object = query_object.filter(Note.id == id)
        query_object = query_object.filter(Note.user_login_id == current_user.get_id())
        query_object = query_object.filter(Note.is_deactivated == False)
        note = query_object.one_or_none()

        if not note:
            return {}, 400

        setattr(note, 'text', args['text'])
        db_session.commit()
        return {'result': 'Note updated'}, 201

    @ns_notes.doc('delete_note')
    def delete(self, id):
        '''Delete selected note'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        query_object = db_session.query(Note)
        query_object = query_object.filter(Note.id == id)
        query_object = query_object.filter(Note.user_login_id == current_user.get_id())
        query_object = query_object.filter(Note.is_deactivated == False)
        note = query_object.one_or_none()

        if not note:
            return {}, 400

        setattr(note, 'is_deactivated', True)
        db_session.commit()
        return {'result': 'Note deleted'}, 201


# Defining playlist resource for API access ==================================
ns_playlist = api.namespace('api/v1/playlist', description='Playlist')

m_playlist = api.model('Playlist', {
    'title': fields.String(required=True, max_length=255, description='The title of the playlist'),
    'description': fields.String(required=True,
                                 description='An extensive description describing the contents of the playlist'),
    'author': fields.String(required=True, max_length=255,
                            description='The author of the playlist. (Not necessarily the logged in user)'),
    'parent': fields.Integer(required=False,
                             description='The id of the parent playlist which the current playlist was based on if any'),
    'license': fields.Integer(default=1, required=True,
                              description='The id of the license information for the current playlist'),
    'is_visible': fields.Boolean(default=True, required=True,
                                 description='Boolean flag to identify if the playlist is visible to the public'),
    'playlist_items': fields.List(fields.Integer, required=True,
                                  description='A list of oer ids to be included in the playlist'),
    'is_temp': fields.Boolean(default=False, required=True,
                              description="Boolean flag to identify if the playlist is temporary or published")
})


def _get_blueprint(title, desc, author, license, items):
    license_obj = repository.get_by_id(License, license)
    base_mapping = {
        "title": title,
        "description": desc,
        "author": author,
        "license": license_obj.description,
        "materials": {}
    }

    # get materials, expects a list of OER ids from X5Learn platform
    for idx, item in enumerate(items):
        temp_item = repository.get_by_id(Oer, item)
        base_mapping["materials"][idx] = {
            "x5learn_id": temp_item.id,
            "url": temp_item.url,
            "metadata": json.loads(temp_item.data)
        }

    return base_mapping


def _add_published_playlist(title, desc, author, license, creator, parent, is_vis, items):
    blueprint = _get_blueprint(title, desc, author, license, items)
    # title, description, author, blueprint, creator, parent, is_visible, license
    playlist = Playlist(title, desc, author, json.dumps(blueprint), creator, parent, is_vis, license)
    playlist = repository.add(playlist)

    count = 0
    for idx, val in enumerate(items):
        playlist_item = Playlist_Item(playlist.id, val, idx)
        playlist_item = repository.add(playlist_item)
        count = count + 1

    return playlist


def _add_temporary_playlist(title, license, creator, parent):
    # if parent is not null, get items
    if parent is not None:
        parent_items = repository.get(Playlist_Item, None, { 'playlist_id' : parent })
        items = [o['oer_id'] for o in parent_items]
    else:
        items = []

    count = len(items)
    payload = {
        "title": title,
        "license": license,
        "parent": parent,
        "playlist_items": items
    }
    temp_playlist = Temp_Playlist(title, creator, json.dumps(payload))
    temp_playlist = repository.add(temp_playlist)

    return {'result': 'Temporary playlist with {} items created'.format(count)}


def _create_oer_record_for_playlist(playlist):
    oer_url = '{}/search?q={}{}'.format(SERVER_NAME, PLAYLIST_PREFIX, playlist['id'])
    oer_data = {
        'url': oer_url,
        'material_id': playlist['id'],
        'title': playlist['title'],
        'provider': 'x5learn',
        'description': playlist['description'],
        'date': playlist['created_at'].strftime("%Y-%m-%d"),
        'duration': '',
        'images': [],
        'mediatype': 'playlist',
        'translations': []
    }

    return Oer(oer_url, oer_data, 'playlist')


def _send_confirmation_email_for_published_playlist(user, title, url):
    if user.email:
        try:
            msg = Message("{} Playlist Published".format(title), sender=MAIL_SENDER, recipients=[user.email])
            msg.body = "Your playlist {} has been succuessfully published <a href='{}' target='_blank'>here</a>.".format(title, oer_url)
            msg.html = render_template('/security/email/base_message.html', user=user, app_name=MAIL_SENDER,
                                        message=msg.body)
            mail.send(msg)
        except Exception:
            return {'result': 'Mail server not configured'}, 400


@ns_playlist.route('/')
class Playlists(Resource):
    '''Create, fetch and delete playlists'''

    @ns_playlist.doc('list_playlists', params={'author': 'Filter by author',
                                               'license': 'Filter by license',
                                               'sort': 'Sort results (Default: desc)',
                                               'offset': 'Offset results',
                                               'limit': 'Limit results'})
    def get(self):
        '''Fetches zero or more playlists created by logged in user from database based on params'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401
        else:
            # Declaring and processing params available for request
            parser = reqparse.RequestParser()
            parser.add_argument('author')
            parser.add_argument('license', type=int)
            parser.add_argument('sort', default='desc', choices=('asc', 'desc'), help='Bad choice')
            parser.add_argument('offset', type=int)
            parser.add_argument('limit', type=int)
            args = parser.parse_args()

            # Building and executing query object
            query_object = db_session.query(Playlist)

            if (args['author']):
                query_object = query_object.filter(Playlist.author == args['author'])

            if (args['license']):
                query_object = query_object.filter(Playlist.license == args['license'])

            query_object = query_object.filter(Playlist.creator == current_user.get_id())

            if (args['sort'] == 'desc'):
                query_object = query_object.order_by(Playlist.created_at.desc())
            else:
                query_object = query_object.order_by(Playlist.created_at.asc())

            if (args['offset']):
                query_object = query_object.offset(args['offset'])

            if (args['limit']):
                query_object = query_object.limit(args['limit'])

            result_list = query_object.all()

            # Converting result list to JSON friendly format
            serializable_list = list()
            if (result_list):
                serializable_list = [i.serialize for i in result_list]

            return serializable_list


    @ns_playlist.doc('create_playlist')
    @ns_playlist.expect(m_playlist, validate=True)
    def post(self):
        '''Creates a new playlist as temporary or published'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        if api.payload['is_temp'] == None or not api.payload['title']:
            return {'result': 'Playlist save type and title is required'}, 400

        # -- publish a playlist --
        if api.payload['is_temp'] == False:
            playlist = _add_published_playlist(api.payload['title'],
                                             api.payload['description'],
                                             api.payload['author'],
                                             _DEFAULT_LICENSE,
                                             current_user.get_id(),
                                             api.payload['parent'],
                                             api.payload['is_visible'],
                                             api.payload['playlist_items'])

            # Deleting temp version of playlist after creating a temp_playlist repo
            temp_playlist_repo = TempPlaylistRepository()
            temp_playlist_repo.delete_by_title(api.payload['title'], current_user.get_id())

            # adding an entry to the OER table by getting the created material id
            oer = _create_oer_record_for_playlist(playlist)
            repository.add(oer)

            # sending confirmation email to the creator with playslist metadata and url for playlist
            user = repository.get_by_id(UserLogin, current_user.get_id())
            _send_confirmation_email_for_published_playlist(user, playlist['title'], oer['url'])

        # -- create a temporary playlist --
        else:
            result = _add_temporary_playlist(api.payload['title'],
                                             _DEFAULT_LICENSE,
                                             current_user.get_id(),
                                             api.payload['parent'])

        return result, 201


@ns_playlist.doc('delete_playlist', params={'id': 'Delete published playlist by id',
                                            'title': 'Delete temporary playlist by title'})
def delete(self):
    '''Delete playlist'''
    if not current_user.is_authenticated:
        return {'result': 'User not logged in'}, 401

    if api.payload['id'] != None:
        playlist = repository.get_by_id(Playlist, api.payload['id'], current_user.get_id())
        if playlist != None:
            playlist_items = repository.get(Playlist_Item, None, {'playlist_id': playlist.id})
            for item in playlist_items:
                repository.delete(item)

        repository.delete(playlist)
        return {'result': 'Playlist - {} was successfully deleted'.format(playlist.title)}, 201

    if api.payload['title'] != None:
        temp_playlist = repository.get(Temp_Playlist, None,
                                       {'title': api.payload['title'], 'creator': current_user.get_id()})
        if temp_playlist != None:
            repository.delete(temp_playlist)

        return {'result': 'Playlist - {} was successfully deleted'.format(temp_playlist.title)}, 201


@ns_playlist.route('/<int:id>')
@ns_playlist.response(404, 'Playlist not found')
@ns_playlist.param('id', 'The playlist identifier')
class Playlist_Single(Resource):
    @ns_playlist.doc('get_playlist')
    def get(self, id):
        '''Fetch requested playlist from database'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        playlist = repository.get_by_id(Playlist, id)

        if playlist is None:
            return {'result': 'Playlist not found'}, 400

        playlist_items = repository.get(Playlist_Item, None,
                                        {'playlist_id': playlist.id, 'creator': current_user.get_id()})
        return {'playlist': playlist.serialize, 'playlist_items': playlist_items}, 200

    @ns_playlist.doc('update_playlist')
    @ns_playlist.expect(m_playlist, validate=True)
    def put(self, id):
        '''Update selected playlist'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        if len(api.payload['playlist_items']) != len(api.payload['playlist_items_order']):
            return {'result': 'One or more arguments for playlist items were found missing.'}, 400

        playlist = repository.get_by_id(Playlist, id, current_user.get_id())
        playlist_items = repository.get(Playlist, None, {'playlist_id': id})

        if playlist is None:
            return {'result': 'Playlist not found'}, 400

        setattr(playlist, 'title', api.payload['title'])
        setattr(playlist, 'description', api.payload['description'])
        setattr(playlist, 'author', api.payload['author'])
        setattr(playlist, 'license', api.payload['license'])
        setattr(playlist, 'parent', api.payload['parent'])
        setattr(playlist, 'is_visible', api.payload['is_visible'])
        repository.update()

        for item in playlist_items:
            repository.delete(item)

        count = 0
        for idx, val in enumerate(api.payload['playlist_items']):
            playlist_item = Playlist_Item(playlist.id, val, api.payload['playlist_items_order'][idx])
            playlist_item = repository.add(playlist_item)
            count = count + 1

        return {'result': 'Playlist with {} items updated and published'.format(count)}, 201

    @ns_playlist.doc('delete_playlist')
    def delete(self, id):
        '''Delete playlist'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        playlist = repository.get_by_id(Playlist, id)

        if playlist is None:
            return {'result': 'Playlist not found'}, 401

        playlist_items = repository.get(Playlist_Item, None, {'playlist_id': playlist.id})
        for item in playlist_items:
            repository.delete(item)

        repository.delete(playlist)
        return {'result': 'Playlist - {} was successfully deleted'.format(playlist.title)}, 201


@ns_playlist.route('/<string:title>')
@ns_playlist.response(404, 'Temporary playlist not found')
@ns_playlist.param('title', 'The temporary playlist identifier')
class Temp_Playlist_Single(Resource):
    @ns_playlist.doc('get_temp_playlist')
    def get(self, title):
        '''Fetch requested temporary playlist from database'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        query_object = db_session.query(Temp_Playlist)
        query_object = query_object.filter(Temp_Playlist.title == title)
        query_object = query_object.filter(Temp_Playlist.creator == current_user.get_id())
        temp_playlist = query_object.one_or_none()

        if temp_playlist is None:
            return {'result': 'Temporary playlist not found'}, 400

        playlist_data = json.loads(temp_playlist['data'])
        playlist = Playlist(playlist_data['title'], playlist_data.get('description', ''),
                            playlist_data.get('author', ''), None, playlist_data.get('creator', None),
                            playlist_data.get('parent', None), playlist_data.get('is_visible', True),
                            playlist_data.get('license', ''))

        playlist_items = []
        for idx, val in enumerate(playlist_data.get('playlist_items', [])):
            playlist_items.append(Playlist_Item(None, val, playlist_data.get('playlist_items', [])[idx]))

        return {'playlist': playlist, 'playlist_items': playlist_items}, 200

    @ns_playlist.doc('update_temp_playlist')
    @ns_playlist.expect(m_playlist, validate=True)
    def put(self, title):
        '''Update temporary playlist from database'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        query_object = db_session.query(Temp_Playlist)
        query_object = query_object.filter(Temp_Playlist.title == title)
        query_object = query_object.filter(Temp_Playlist.creator == current_user.get_id())
        temp_playlist = query_object.one_or_none()

        if temp_playlist is None:
            return {'result': 'Temporary playlist not found'}, 400

        setattr(temp_playlist, 'title', api.payload['title'])
        setattr(temp_playlist, 'data', json.dumps(api.payload))
        repository.update()

        return {'result': 'Temporary playlist successfully updated'}, 201

    @ns_playlist.doc('delete_temporary_playlist')
    def delete(self, id):
        '''Delete temporary playlist'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401

        query_object = db_session.query(Temp_Playlist)
        query_object = query_object.filter(Temp_Playlist.title == title)
        query_object = query_object.filter(Temp_Playlist.creator == current_user.get_id())
        temp_playlist = query_object.one_or_none()

        if temp_playlist is None:
            return {'result': 'Temporary playlist not found'}, 400

        repository.delete(temp_playlist)
        return {'result': 'Temporary playlist successfully deleted'}, 201


def initiate_action_types_table():
    # TODO Define a comprehensive set of actions and keep it in sync with the frontend
    # BTW in case a reset is needed: https://stackoverflow.com/a/5342503/2237986
    action_type = ActionType.query.filter_by(id=1).first()
    if action_type is None:
        action_type = ActionType('OER card opened')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=2).first()
    if action_type is None:
        action_type = ActionType('OER marked as favorite (no longer in use)')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=3).first()
    if action_type is None:
        action_type = ActionType('OER unmarked as favorite (no longer in use)')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=4).first()
    if action_type is None:
        action_type = ActionType('Video played')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=5).first()
    if action_type is None:
        action_type = ActionType('Video paused')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=6).first()
    if action_type is None:
        action_type = ActionType('Video seeked')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=7).first()
    if action_type is None:
        action_type = ActionType('ContentFlow setting changed')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=8).first()
    if action_type is None:
        action_type = ActionType('Feedback on OER content')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=9).first()
    if action_type is None:
        action_type = ActionType('Video still playing')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=10).first()
    if action_type is None:
        action_type = ActionType('OverviewType selected')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=11).first()
    if action_type is None:
        action_type = ActionType('ToggleExplainer')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=12).first()
    if action_type is None:
        action_type = ActionType('OpenExplanationPopup')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=13).first()
    if action_type is None:
        action_type = ActionType('TriggerSearch')
        db_session.add(action_type)
        db_session.commit()
    action_type = ActionType.query.filter_by(id=14).first()
    if action_type is None:
        action_type = ActionType('UrlChanged')
        db_session.add(action_type)
        db_session.commit()


def find_enrichment_by_oer_id(oer_id):
    # Querying the JSON field this way resulted in bizarre CPU load on my Mac.
    # enrichment = WikichunkEnrichment.query.filter(
    #     WikichunkEnrichment.data['oerId'].astext.cast(Integer) == oer_id).first()
    # The following quick fix takes a small detour by loading the OER.
    # NB a more performant solution would be to add an oer_id column
    # to WikichunkEnrichment but is beyond the scope of this issue.
    oer = Oer.query.get(oer_id)
    if oer is None:
        return None
    return WikichunkEnrichment.query.filter_by(url=oer.url).first()


# old solution - wouldn't scale well to millions of oers - see issue #290
def recommendations_from_wikichunk_enrichments(oer_id):
    main_topics = find_enrichment_by_oer_id(oer_id).main_topics()
    print(main_topics)
    urls_with_similarity = [(enrichment.url, enrichment.get_topic_overlap(main_topics)) for enrichment in
                            WikichunkEnrichment.query.all()]
    most_similar = sorted(urls_with_similarity, key=lambda x: x[1], reverse=True)
    results = []
    for candidate in most_similar:
        oer = Oer.query.filter_by(url=candidate[0]).first()
        if oer is not None and 'youtu' not in oer.url:
            results.append(oer)
        if len(results) > 9:
            break
    return results


# new solution - using LAM API (Nantes) - see issue #290
def recommendations_from_lam_api(oer_id):
    # LAM API base url
    LAM_API_URL = "http://wp3.x5gon.org"

    # setup appropriate headers
    HEADERS = {
        'accept': 'application/json',
        'Content-Type': 'application/json',
    }

    # endpoint
    RECOMMENDER_ENDPOINT = '/recommendsystem/v1'

    # Ensure that the OER exists
    oer = Oer.query.get(oer_id)
    if oer is None:
        print('WARNING: requested recommendations for missing OER', oer_id)
        return []

    material_id = int(oer.data['material_id'])

    # request enough items so we can filter the results by type afterwards
    # TODO: get the API improved so that we can filter as part of the request
    data = {'resource_id': material_id, 'n_neighbors': 20, 'remove_duplicates': 1, 'model_type': 'wikifier'}
    response = requests.post(LAM_API_URL + RECOMMENDER_ENDPOINT,
                             headers=HEADERS,
                             data=json.dumps(data))
    response_json = response.json()
    try:
        materials = response_json['output']['rec_materials']
    except KeyError as err:
        print('KeyError')
        print(err)
        print(err.args)
        print(type(response_json))
        print(response_json)
        return []
    oers = []
    for material in materials:
        # print(material['material_id'], material['weight'], material['type'])
        # stop once we have enough items
        if len(oers) > 4:
            break
        # include only supported media formats
        if material['type'] not in SUPPORTED_FILE_FORMATS:
            continue
        url = material['url']
        # Some urls that were longer than 255 caused errors.
        # TODO: change the type of all url colums from String(255) to Text()
        # Temporary fix: ignore search results with very long urls
        if len(url) > 255:
            continue
        oer = retrieve_oer_or_create_from_x5gon_material(material)
        oers.append(oer)
    return oers


def find_oer_by_material_id(material_id):
    return Oer.query.filter(Oer.data['material_id'].astext == str(material_id)).order_by(Oer.id.desc()).first()


if __name__ == '__main__':
    app.run()
