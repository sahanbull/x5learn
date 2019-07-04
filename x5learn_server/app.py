from x5learn_server.models import UserLogin, Role, User, Oer, WikichunkEnrichment, WikichunkEnrichmentTask, EntityDefinition, Note, Action, ActionType
from x5learn_server.labstudyone import get_dataset_for_lab_study_one
from x5learn_server.models import UserLogin, Role, User, Oer, WikichunkEnrichment, WikichunkEnrichmentTask, EntityDefinition, LabStudyLogEvent
from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET, MAIL_USERNAME, MAIL_PASS, MAIL_SERVER, MAIL_PORT
from x5learn_server.models import UserLogin, Role, User, Oer, WikichunkEnrichment, WikichunkEnrichmentTask, EntityDefinition, Note
from x5learn_server.db.database import db_session
from x5learn_server.db.database import get_or_create_session_db
from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET, LATEST_API_VERSION
from flask import Flask, jsonify, render_template, request, redirect
from flask_mail import Mail, Message
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
from flask_restplus import Api, Resource, fields, reqparse


# instantiate the user management db classes
from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET, LATEST_API_VERSION, MAIL_USERNAME, MAIL_PASS, MAIL_SERVER, MAIL_PORT
from x5learn_server.db.database import get_or_create_session_db

get_or_create_session_db(DB_ENGINE_URI)


# Create app
app = Flask(__name__)
mail = Mail()

app.config['DEBUG'] = True
app.config['SECRET_KEY'] = PASSWORD_SECRET
app.config['SECURITY_PASSWORD_HASH'] = "bcrypt"
app.config['SECURITY_PASSWORD_SALT'] = PASSWORD_SECRET

# user registration configs
app.config['SECURITY_REGISTERABLE'] = True
app.config['SECURITY_REGISTER_URL'] = '/signup'
app.config['SECURITY_SEND_REGISTER_EMAIL'] = True
app.config['SECURITY_CONFIRMABLE'] = True

# user password configs
app.config['SECURITY_CHANGEABLE'] = True
app.config['SECURITY_CHANGE_URL'] = '/password_change'
app.config['SECURITY_EMAIL_SENDER'] = MAIL_USERNAME
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
app.config['MAIL_DEFAULT_SENDER'] = MAIL_USERNAME

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
    if user_id is None or user_id == '':  # No cookie set
        return new_guest_session()
    user = User.query.get(user_id)
    if user is None:  # The cookie points to a row which no longer exists
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
    profile = current_user.user_profile if current_user.user_profile is not None else {
        'email': current_user.email}
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
    if user is None:  #  This will happen for the handful of people who have signed up before this change and have been warned that their user state will be reset. Other than that, there is no good reasons for current_user.user to ever be None. So at a later point, we may want to replace this entire function with simply current_user.user
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
        if user_id == None or user_id == '':  # If the user cleared their cookie while using the app
            return new_guest_ok('OK')
        user = User.query.get(user_id)
        if user is None:  # In the rare case that the cookie points to no-longer existent row
            return new_guest_ok('OK')
        user.frontend_state = frontend_state
        db_session.commit()
        return 'OK'


@app.route("/api/v1/search/", methods=['GET'])
def api_search():
    text = request.args['text'].lower().strip()
    results = get_dataset_for_lab_study_one(
        text) or search_results_from_x5gon_api(text)
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
    enrichments = {}
    for url in request.get_json()['urls']:
        enrichment = WikichunkEnrichment.query.filter_by(url=url).first()
        if enrichment is not None:
            enrichments[url] = enrichment.data
        else:
            push_enrichment_task(url, 1)
    return jsonify(enrichments)


@app.route("/api/v1/most_urgent_unstarted_enrichment_task/", methods=['POST'])
def most_urgent_unstarted_enrichment_task():
    timeout = datetime.now() - timedelta(minutes=10)
    task = WikichunkEnrichmentTask.query.filter(and_(WikichunkEnrichmentTask.error == None, or_(
        WikichunkEnrichmentTask.started == None, WikichunkEnrichmentTask.started < timeout))).order_by(WikichunkEnrichmentTask.priority.desc()).first()
    if task is None:
        return jsonify({'info': 'No tasks available'})
    url = task.url
    print('Starting task with priority:', task.priority, 'url:', url)
    task.started = datetime.now()
    task.priority = 0
    db_session.commit()
    oer = Oer.query.filter_by(url=url).first()
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
    else:
        db_session.delete(task)
    db_session.commit()
    save_enrichment(url, data)
    save_definitions(data)
    return 'OK'


@app.route("/api/v1/entity_definitions/", methods=['GET'])
def api_entity_descriptions():
    entity_ids = request.args['ids'].split(',')
    definitions = {}
    for entity_id in entity_ids:
        entity_definition = EntityDefinition.query.filter_by(
            entity_id=entity_id).first()
        definitions[entity_id] = entity_definition.extract if entity_definition is not None else ''
    return jsonify(definitions)


@app.route("/api/v1/log_event_for_lab_study/", methods=['POST'])
def log_event_for_lab_study():
    if current_user.is_authenticated:
        email = current_user.email
        if email.endswith('.lab'):
            j = request.get_json(force=True)
            event = LabStudyLogEvent(
                email, j['eventType'], j['params'], j['browserTime'])
            db_session.add(event)
            db_session.commit()
    return 'OK'


def save_enrichment(url, data):
    enrichment = WikichunkEnrichment.query.filter_by(url=url).first()
    if enrichment is None:
        enrichment = WikichunkEnrichment(url, data, CURRENT_ENRICHMENT_VERSION)
        db_session.add(enrichment)
    else:
        enrichment.data = data
        enrichment.version = CURRENT_ENRICHMENT_VERSION
    db_session.commit()


def save_definitions(data):
    for chunk in data['chunks']:
        for entity in chunk['entities']:
            title = entity['title']
            # print(title, '...')
            definition = EntityDefinition.query.filter_by(title=title).first()
            if definition is None:
                encoded_title = urllib.parse.quote(title)
                conn = http.client.HTTPSConnection('en.wikipedia.org')
                conn.request(
                    'GET', '/w/api.php?action=query&prop=extracts&exintro&explaintext&exsentences=1&titles='+encoded_title+'&format=json')
                response = conn.getresponse().read().decode("utf-8")
                pages = json.loads(response)['query']['pages']
                (_, page) = pages.popitem()
                extract = page['extract']
                # print(extract)
                definition = EntityDefinition(
                    entity['id'], title, entity['url'], extract)
                db_session.add(definition)
                db_session.commit()


def search_results_from_x5gon_api(text):
    max_results = 18
    encoded_text = urllib.parse.quote(text)
    conn = http.client.HTTPSConnection("platform.x5gon.org")
    conn.request(
        'GET', '/api/v1/search/?url=https://platform.x5gon.org/materialUrl&type=all&text='+encoded_text)
    response = conn.getresponse().read().decode("utf-8")
    materials = json.loads(response)['rec_materials'][:max_results]
    # materials = [ m for m in materials if m['url'].endswith('.pdf') ] # filter by suffix
    materials = [m for m in materials if m['url'].endswith(
        '.pdf') or is_video(m['url'])]  # filter by suffix
    # crudely filter out materials from MIT OCW that are assignments or date back to the 90s or early 2000s
    materials = [m for m in materials if '/assignments/' not in m['url']
                 and '199' not in m['url'] and '200' not in m['url']]
    # Exclude non-english materials because they tend to come out poorly after wikification. X5GON search doesn't have a language parameter at the time of writing.
    materials = [m for m in materials if m['language'] == 'en']
    materials = remove_duplicates_from_search_results(materials)
    oers = []
    for index, material in enumerate(materials):
        url = material['url']
        oer = Oer.query.filter_by(url=url).first()
        if oer is None:
            oer = Oer(url, convert_x5_material_to_oer(material, url))
            db_session.add(oer)
            db_session.commit()
        oers.append(oer.data)
        enrichment = WikichunkEnrichment.query.filter_by(url=url).first()
        if (enrichment is None) or (enrichment.version != CURRENT_ENRICHMENT_VERSION):
            push_enrichment_task(url, int(1000/(index+1)) + 1)
    return oers


def remove_duplicates_from_search_results(materials):
    enrichments = {}
    urls = [m['url'] for m in materials]
    for enrichment in WikichunkEnrichment.query.filter(WikichunkEnrichment.url.in_(urls)).all():
        enrichments[enrichment.url] = enrichment
    included_materials = []
    included_enrichments = []

    def is_duplicate(material):
        url = material['url']
        # For materials that haven't been enriched yet, we can't tell whether they are identical.
        if url not in enrichments:
            return False
        enrichment = enrichments[url]
        for e in included_enrichments:
            if fuzz.ratio(e.entities_to_string(), enrichment.entities_to_string()) > 90:
                return True
        return False
    for m in materials:
        if not is_duplicate(m):
            included_materials.append(m)
            url = m['url']
            if url in enrichments:
                included_enrichments.append(enrichments[url])
    return included_materials


def convert_x5_material_to_oer(material, url):
    # Insert some fields that the frontend expects, using values from the x5gon search result when possible, otherwise default values.
    data = {}
    data['url'] = url
    data['title'] = material['title'] or '(Title unavailable)'
    data['provider'] = material['provider'] or ''
    data['description'] = material['description'] or ''
    data['date'] = ''
    data['duration'] = ''
    data['images'] = []
    data['mediatype'] = material['type']
    return data


def push_enrichment_task(url, priority):
    # print('push_enrichment_task')
    task = WikichunkEnrichmentTask.query.filter_by(url=url).first()
    if task is None:
        task = WikichunkEnrichmentTask(url, priority)
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
    all_entity_titles = []  # TODO: use Topics table in db
    matches = [(title, fuzz.partial_ratio(text, title) +
                fuzz.ratio(text, title)) for title in all_entity_titles]
    matches = sorted(matches, key=lambda k_v: k_v[1], reverse=True)[:20]
    print([v for k, v in matches])
    matches = [k for k, v in matches]
    # import pdb; pdb.set_trace()
    # print(matches)
    return jsonify(matches)


def find_oer_by_url(url):
    oer = Oer.query.filter_by(url=url).first()
    if oer is not None:
        return oer.data
    else:
        # Return a blank OER. This should not happen normally
        oer = {}
        oer['date'] = ''
        oer['description'] = '(Sorry, this resource is no longer accessible)'
        oer['duration'] = ''
        oer['images'] = []
        oer['provider'] = ''
        oer['title'] = '(not found)'
        oer['url'] = url
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
# (Not an expert on this - grateful for any clarification)
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


# Defining notes resource for API access
ns_notes = api.namespace('api/v1/note', description='Notes')

m_note = api.model('Note', {
    'oer_id': fields.String(required=True, max_length=255, description='The material id of the note associated with'),
    'text': fields.String(required=True, description='The content of the note')
})


@ns_notes.route('/')
class NotesList(Resource):
    '''Shows a list of all notes, and lets you POST to add new notes'''
    @ns_notes.doc('list_notes', params={'oer_id': 'Filter result set by material id',
                                        'sort': 'Sort results by timestamp (Default: desc)',
                                        'offset': 'Offset result set by number specified (Default: 0)',
                                        'limit': 'Limits the number of records in the result set (Default: None)'})
    def get(self):
        '''Fetches multiple notes from database based on params'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401
        else:
            # Declaring and processing params available for request
            parser = reqparse.RequestParser()
            parser.add_argument('oer_id', type=int)
            parser.add_argument('sort', default='desc', choices=(
                'asc', 'desc'), help='Bad choice')
            parser.add_argument('offset', type=int)
            parser.add_argument('limit', type=int)
            args = parser.parse_args()

            # Building and executing query object
            query_object = db_session.query(Note)

            if (args['oer_id']):
                query_object = query_object.filter(
                    Note.oer_id == args['oer_id'])

            query_object = query_object.filter(
                Note.user_login_id == current_user.get_id())
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
            note = Note(
                api.payload['oer_id'], api.payload['text'], current_user.get_id(), False)
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
        query_object = query_object.filter(
            Note.user_login_id == current_user.get_id())
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
        query_object = query_object.filter(
            Note.user_login_id == current_user.get_id())
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
        query_object = query_object.filter(
            Note.user_login_id == current_user.get_id())
        query_object = query_object.filter(Note.is_deactivated == False)
        note = query_object.one_or_none()

        if not note:
            return {}, 400

        setattr(note, 'is_deactivated', True)
        db_session.commit()
        return {'result': 'Note deleted'}, 201


# Defining actions resource for API access
ns_action = api.namespace('api/v1/action', description='Actions')

m_action = api.model('Action', {
    'action_type_id': fields.Integer(required=True, description='The action type id for the action'),
    'params': fields.String(required=True, description='A json object with params related to the action')
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
            parser.add_argument('offset', type=int)
            parser.add_argument('limit', type=int)
            args = parser.parse_args()

            # Building and executing query object
            query_object = db_session.query(
                Action, ActionType).join(ActionType)

            if (args['action_type_id']):
                query_object = query_object.filter(
                    Action.action_type_id == args['action_type_id'])

            query_object = query_object.filter(
                Action.user_login_id == current_user.get_id())

            if (args['sort'] == 'desc'):
                query_object = query_object.order_by(Action.created_at.desc())
            else:
                query_object = query_object.order_by(Action.created_at.asc())

            if (args['offset']):
                query_object = query_object.offset(args['offset'])

            if (args['limit']):
                query_object = query_object.limit(args['limit'])

            result_list = query_object.all()

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
                        temp_oer = db_session.query(Oer).filter(
                            Oer.id == temp_list['oer_id']).one_or_none()
                        if temp_oer.data:
                            if 'title' in temp_oer.data:
                                tempObject['params']['title'] = temp_oer.data['title']

                    serializable_list.append(tempObject)

            return serializable_list

    @ns_action.doc('log_action')
    @ns_action.expect(m_action, validate=True)
    def post(self):
        '''Log action to database'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401
        elif not api.payload['action_type_id']:
            return {'result': 'Action type id is required'}, 400
        else:
            action = Action(api.payload['action_type_id'], json.loads(
                api.payload['params']), current_user.get_id())
            db_session.add(action)
            db_session.commit()
            return {'result': 'Action logged'}, 201

# Defining user resource for API access
ns_user = api.namespace('api/v1/user', description='User')

@ns_user.route('/forget')
class UserApi(Resource):
    '''Api to manage user'''

    def delete(self):
        '''Delete user actions, notes and user'''
        if not current_user.is_authenticated:
            return {'result': 'User not logged in'}, 401
        else:
            id = current_user.get_id()
            user = db_session.query(UserLogin).get(id)

            Action.query.filter(Action.user_login_id == id).delete()
            Note.query.filter(Note.user_login_id == id).delete()
            User.query.filter(User.id == id).delete()
            db_session.delete(user)
            db_session.commit()

            # Sending confirmation mail
            if user.email:
                try:
                    msg = Message("x5Learn Account Deleted", sender=MAIL_USERNAME, recipients=[user.email])
                    msg.body = "Your account and related data has been deleted."
                    msg.html = render_template('/security/email/base_message.html', user=user, app_name=MAIL_USERNAME, message=msg.body)
                    mail.send(msg)
                except Exception:
                    return {'result': 'Mail server not configured'}, 400

            return {'result': 'User deleted'}, 200


if __name__ == '__main__':
    app.run()
