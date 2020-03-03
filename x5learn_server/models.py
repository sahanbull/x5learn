from x5learn_server.db.database import Base, get_or_create_db
from x5learn_server._config import DB_ENGINE_URI
from flask_security import UserMixin, RoleMixin
from sqlalchemy.orm import relationship, backref
from sqlalchemy import Boolean, DateTime, Column, Integer, \
    Text, String, ForeignKey, BigInteger, Float
from sqlalchemy.dialects.postgresql import JSON
import datetime


class RolesUsers(Base):
    __tablename__ = 'roles_users'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    user_id = Column('user_id', Integer(), ForeignKey('user_login.id'))
    role_id = Column('role_id', Integer(), ForeignKey('role.id'))


class Role(Base, RoleMixin):
    __tablename__ = 'role'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    name = Column(String(80), unique=True)
    description = Column(String(255))


class UserLogin(Base, UserMixin):
    __tablename__ = 'user_login'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True)
    password = Column(String(255))
    last_login_at = Column(DateTime())
    current_login_at = Column(DateTime())
    last_login_ip = Column(String(100))
    current_login_ip = Column(String(100))
    login_count = Column(Integer)
    active = Column(Boolean())
    confirmed_at = Column(DateTime())
    roles = relationship('Role', secondary='roles_users',
                         backref=backref('user_login', lazy='dynamic'))
    user_profile = Column(JSON())
    user = relationship('User', uselist=False, backref='user_login')


# I suspect that the User table is obsolete
class User(Base):
    __tablename__ = 'user'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    frontend_state = Column(JSON())
    user_login_id = Column(Integer, ForeignKey('user_login.id'))


class Oer(Base):
    __tablename__ = 'oer'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    url = Column(Text(), nullable=False)
    data = Column(JSON())

    def __init__(self, url, data):
        self.url = url
        self.data = data

    def data_and_id(self):
        # Ensure that image and date fields have the correct types.
        # This is just a lazy patch for pdfs that were poorly imported from csv.
        # TODO remove the if statements below after re-importing the pdfs.
        if 'durationInSeconds' not in self.data:
            self.data['durationInSeconds']=0.001 # tiny default value causes frontend to report the real duration
        if self.data['images']=='[]':
            self.data['images']=[]
        if not isinstance(self.data['date'], str):
            self.data['date'] = str(self.data['date'])
        result = {**self.data}
        result['id'] = self.id
        return result


class WikichunkEnrichment(Base):
    __tablename__ = 'wikichunk_enrichment'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    url = Column(String(255), nullable=False)
    data = Column(JSON)
    version = Column(Integer())

    def __init__(self, url, data, version):
        self.url = url
        self.data = data
        self.version = version

    def get_entity_titles(self):
        titles = []
        for chunk in self.data['chunks']:
            for entity in chunk['entities']:
                titles.append(entity['title'])
        return titles

    def entities_to_string(self):
        return ','.join([','.join([e['title'] for e in chunk['entities']]) for chunk in self.data['chunks']])

    def all_entity_titles_as_lowercase_strings(self):
        result = []
        for chunk in self.data['chunks']:
            result += [ e['title'].lower() for e in chunk['entities'] ]
        return result

    def full_text(self):
        return ' '.join([ chunk['text'] for chunk in self.data['chunks'] ])

    def main_topics(self):
        return [y for z in self.data['clusters'] for y in z] # concat lists

    def get_topic_overlap(self, topics):
        overlap = 0
        for topic in self.main_topics():
            if topic in topics:
                overlap += 1
        return overlap


class WikichunkEnrichmentTask(Base):
    __tablename__ = 'wikichunk_enrichment_task'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    url = Column(String(255), unique=True, nullable=False)
    priority = Column(Integer())
    started = Column(DateTime())
    error = Column(String(255))

    def __init__(self, url, priority):
        self.url = url
        self.priority = priority


class EntityDefinition(Base):
    __tablename__ = 'entity_definition'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    entity_id = Column(String(20))
    title = Column(String(255))
    url = Column(String(255))
    extract = Column(Text())
    last_update_at = Column(DateTime(), default=datetime.datetime.utcnow)
    lang = Column(String(20))

    def __init__(self, entity_id, title, url, extract, lang):
        self.entity_id = entity_id
        self.title = title
        self.url = url
        self.extract = extract
        self.last_update_at = datetime.datetime.utcnow()
        self.lang = lang

    @property
    def serialize(self):
        """Return object data in easily serializable format"""
        return {
            'id': self.id,
            'entity_id': self.entity_id,
            'title': self.title,
            'url': self.params,
            'extract': self.extract,
            'last_update_at': dump_datetime(self.last_update_at),
            'lang': self.lang
        }


def dump_datetime(value):
    """Deserialize datetime object into string form for JSON processing."""
    if value is None:
        return None
    return value.strftime("%Y-%m-%dT%H:%M:%S") + '+00:00'


class ActionType(Base):
    __tablename__ = 'action_type'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    description = Column(String(255))

    def __init__(self, description):
        self.description = description

    @property
    def serialize(self):
        """Return object data in easily serializable format"""
        return {
            'id': self.id,
            'description': self.description
        }


class Action(Base):
    __tablename__ = 'action'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    action_type_id = Column(Integer, ForeignKey('action_type.id'))
    params = Column(JSON)
    created_at = Column(DateTime(), default=datetime.datetime.utcnow)
    user_login_id = Column(Integer, ForeignKey('user_login.id'))

    def __init__(self, action_type_id, params, user_login_id):
        self.action_type_id = action_type_id
        self.params = params
        self.user_login_id = user_login_id

    @property
    def serialize(self):
        """Return object data in easily serializable format"""
        return {
            'id': self.id,
            'action_type_id': self.action_type_id,
            'params': self.params,
            'created_at': dump_datetime(self.created_at),
            'user_login_id': self.user_login_id
        }


class ResourceFeedback(Base):
    __tablename__ = 'resource_feedback'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    user_login_id = Column(Integer())
    oer_id = Column(Integer())
    text = Column(Text())
    created_at = Column(DateTime())

    def __init__(self, user_login_id, oer_id, text):
        self.user_login_id = user_login_id
        self.oer_id = oer_id
        self.text = text
        self.created_at = datetime.datetime.now()


class Course(Base):
    __tablename__ = 'course'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    user_login_id = Column(Integer())
    data = Column(JSON())
    created_at = Column(DateTime())

    def __init__(self, user_login_id, data):
        self.user_login_id = user_login_id
        self.data = data
        self.created_at = datetime.datetime.now()


class UiLogBatch(Base):
    __tablename__ = 'ui_log_batch'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    user_login_id = Column(Integer())
    client_time = Column(String())
    events = Column(JSON())
    created_at = Column(DateTime())

    def __init__(self, user_login_id, client_time, text):
        self.user_login_id = user_login_id
        self.client_time = client_time
        self.created_at = datetime.datetime.now()
        self.events = self.parse_events(text)

    def parse_events(self, text):
        events = []
        for line in text.split('\n'):
            s = line.split(' ')
            events.append({'clientTime': s[0], 'eventType': s[1], 'args': s[2:]})
        # import pdb; pdb.set_trace()
        print(events)
        print()
        return events


# Repository pattern implemented for CRUD
class Repository:
    """
    represents a data layer object for CRUD operations
    """

    def __init__(self):
        self._db_session = get_or_create_db(DB_ENGINE_URI)

    def get_by_id(self, item, id, user_login_id=None):
        """get a single designated item by id. Optionally can auth by user login id

        Args:
            item (object): type of db object to query (Required)
            id (int): id to query object by (Required)
            user_login_id (int): user login id to auth records belonging to the user

        Returns:
            (object): object of type item

        """

        query_object = self._db_session.query(item)

        if (user_login_id):
            query_object = query_object.filter_by(
                user_login_id=user_login_id)

        return query_object.filter_by(id=id).one_or_none()

    def get(self, item, user_login_id, filters=None, sort=None):
        """gets multiple items. Optionally can auth by user login id

        Args:
            item (object): type of db object to query (Required)
            user_login_id (int): user login id to auth records belonging to the user
            filters (dict{key:val}): keys will be columns to filter, values are the value to filter with
            sort (dict{key:val}):  key will be column to sort by, value will be 'asc' or 'desc'

        Returns:
            (list(object)): list of objects of type item

        """

        query_object = self._db_session.query(item)

        if (user_login_id):
            query_object = query_object.filter_by(
                user_login_id=user_login_id)

        if filters:
            for key, value in filters.items():
                query_object = query_object.filter(getattr(item, key) == value)

        if sort:
            for key, value in sort.items():
                if value == "asc":
                    query_object.order_by((getattr(item, key)).asc())
                else:
                    query_object.order_by((getattr(item, key)).desc())

        return query_object.all()

    def add(self, item):
        """add an a record of type item to the db.

        Args:
            item (object): type of db object to add (Required)

        Returns:
            (object): returns added item

        """

        self._db_session.add(item)
        self._db_session.commit()
        return item

    def update(self):
        """syncs modified records with the relevant database records.

        Args:
            item (object): type of db object to update (Required)

        Returns:
            (object): returns updated item

        """

        self._db_session.commit()
        return True

    def delete(self, item):
        """deletes an a record of type item from the db.

        Args:
            item (object): type of db object to delete (Required)

        """

        self._db_session.delete(item)
        self._db_session.commit()


class ActionsRepository(Repository):

    def get_actions(self, user_login_id, action_type_id=None, sort="desc", offset=None, limit=None):
        """gets multiple actions filtered by user logged in.

        Args:
            user_login_id (int): user login id to auth records belonging to the user
            action_type_id (int): filter actions attached to a specific action type
            sort (str): sort by 'asc' or 'desc'
            offset (int): Number to offset result set with (Default: 0)
            limit (int): Number to limit records of result set (Default: None)

        Returns:
            (list(object)): list of objects of type actions

        """

        query_object = self._db_session.query(
            Action, ActionType).join(ActionType)

        if (action_type_id):
            query_object = query_object.filter(
                Action.action_type_id == action_type_id)

        query_object = query_object.filter(
            Action.user_login_id == user_login_id)

        if (sort == 'desc'):
            query_object = query_object.order_by(Action.created_at.desc())
        else:
            query_object = query_object.order_by(Action.created_at.asc())

        if (offset):
            query_object = query_object.offset(offset)

        if (limit):
            query_object = query_object.limit(limit)

        return query_object.all()


class UserRepository(Repository):

    def forget_user(self, user, user_login_id):
        """deletes a user and any related info completely off the database.

        Args:
            user (object): user to be deleted (Required)
            user_login_id (int): user login id to auth delete action (Required)

        Returns:
            (bool) : true

        """

        self._db_session.query(Action).filter_by(
            user_login_id=user_login_id).delete()
        self._db_session.query(User).filter_by(
            user_login_id=user_login_id).delete()

        self._db_session.delete(user)
        self._db_session.commit()
        return True


class DefinitionsRepository(Repository):

    def get_definitions_list(self, titles):
        """fetches definitions from database for given list of titles.

        Args:
            titles (list(str)): list of string that should be queried from databse (Required)

        Returns:
            (list(objects)) : list of objects containing definition related data

        """

        return self._db_session.query(EntityDefinition).filter(EntityDefinition.title.in_(titles)).all()
