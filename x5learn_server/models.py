from x5learn_server.db.database import Base
from flask_security import UserMixin, RoleMixin
from sqlalchemy.orm import relationship, backref
from sqlalchemy import Boolean, DateTime, Column, Integer, \
    Text, String, JSON, Float, ForeignKey, Table, func
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
    roles = relationship('Role', secondary='roles_users', backref=backref('user_login', lazy='dynamic'))
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
        return '. '.join([ '. '.join([ e['title'] for e in chunk['entities'] ]) for chunk in self.data['chunks'] ])


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

    def __init__(self, entity_id, title, url, extract):
        self.entity_id = entity_id
        self.title = title
        self.url = url
        self.extract = extract


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
    description =  Column(String(255))

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
