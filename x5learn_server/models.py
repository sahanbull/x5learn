from x5learn_server.db.database import Base, get_or_create_db
from x5learn_server._config import DB_ENGINE_URI
from flask_security import UserMixin, RoleMixin, current_user
from sqlalchemy.orm import relationship, backref
from sqlalchemy import Boolean, DateTime, Column, Integer, \
    Text, String, JSON, Float, ForeignKey, Table, func, BigInteger
import datetime
from flask_sqlalchemy import SQLAlchemy


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
    url = Column(String(255), unique=True, nullable=False)
    data = Column(JSON())

    def __init__(self, url, data):
        self.url = url
        self.data = data


class WikichunkEnrichment(Base):
    __tablename__ = 'wikichunk_enrichment'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    url = Column(String(255), unique=True, nullable=False)
    data = Column(JSON())
    version = Column(Integer())

    def __init__(self, url, data, version):
        self.url = url
        self.data = data
        self.version = version

    def entities_to_string(self):
        return '. '.join(['. '.join([e['title'] for e in chunk['entities']]) for chunk in self.data['chunks']])


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
    url = Column(String(255), unique=True)
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
    return [value.strftime("%Y-%m-%d"), value.strftime("%H:%M:%S")]


class Note(Base):
    __tablename__ = 'note'
    __table_args__ = {'extend_existing': True}
    id = Column(Integer(), primary_key=True)
    text = Column(Text())
    created_at = Column(DateTime(), default=datetime.datetime.utcnow)
    last_updated_at = Column(DateTime())
    user_login_id = Column(Integer, ForeignKey('user_login.id'))
    oer_id = Column(Integer, ForeignKey('oer.id'))
    is_deactivated = Column(Boolean())

    def __init__(self, oer_id, text, user_login_id, is_deactivated):
        self.oer_id = oer_id
        self.text = text
        self.last_updated_at = datetime.datetime.utcnow()
        self.user_login_id = user_login_id
        self.is_deactivated = is_deactivated

    @property
    def serialize(self):
        """Return object data in easily serializable format"""
        return {
            'id': self.id,
            'oer_id': self.oer_id,
            'text': self.text,
            'created_at': dump_datetime(self.created_at),
            'last_updated_at': dump_datetime(self.last_updated_at),
            'user_login_id': self.user_login_id,
            'is_deactivated': self.is_deactivated
        }


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

# This table is only used for the purpose of conducting lab-based evaluations of user experience at UCL.


class LabStudyLogEvent(Base):
    __tablename__ = 'lab_study_log_event'
    id = Column(Integer(), primary_key=True)
    participant = Column(String(255))
    event_type = Column(String(40))
    params = Column(String())
    browser_time = Column(BigInteger())
    created_at = Column(DateTime())

    def __init__(self, participant, event_type, params, browser_time):
        self.participant = participant
        self.event_type = event_type
        self.params = params
        self.browser_time = browser_time
        self.created_at = datetime.datetime.now()


# Repository pattern implemented for CRUD

db_session = None


class Repository:

    def __init__(self):
        global db_session
        db_session = get_or_create_db(DB_ENGINE_URI)

    def get_by_id(self, item, id, auth_user=False):
        global db_session
        query_object = db_session.query(item)

        if (auth_user):
            query_object = query_object.filter_by(user_login_id=current_user.get_id())

        return query_object.filter_by(id=id).one_or_none()

    def get(self, item, filters, sort, order):
        global db_session
        result = db_session.query(item)
        return result

    def add(self, item):
        global db_session
        db_session.add(item)
        db_session.commit()
        return item

    def update(self, item):
        global db_session
        db_session.commit()
        return item

    def delete(self, item):
        global db_session
        db_session.delete(item)
        db_session.commit()


class NotesRepository(Repository):

    def __init__(self):
        pass

    def get_notes(self, oer_id=None, sort="desc", offset=None, limit=None):
        global db_session
        query_object = db_session.query(Note)

        if (oer_id):
            query_object = query_object.filter(Note.oer_id == oer_id)

        query_object = query_object.filter_by(user_login_id=current_user.get_id())
        query_object = query_object.filter_by(is_deactivated=False)

        if (sort == 'desc'):
            query_object = query_object.order_by(Note.created_at.desc())
        else:
            query_object = query_object.order_by(Note.created_at.asc())

        if (offset):
            query_object = query_object.offset(offset)

        if (limit):
            query_object = query_object.limit(limit)

        return query_object.all()
