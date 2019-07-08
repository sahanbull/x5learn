from x5learn_server.db.database import Base
from flask_security import UserMixin, RoleMixin
from sqlalchemy.orm import relationship, backref
from sqlalchemy import Boolean, DateTime, Column, Integer, BigInteger, \
    Text, String, JSON, Float, ForeignKey, Table

from datetime import datetime

class RolesUsers(Base):
    __tablename__ = 'roles_users'
    id = Column(Integer(), primary_key=True)
    user_id = Column('user_id', Integer(), ForeignKey('user_login.id'))
    role_id = Column('role_id', Integer(), ForeignKey('role.id'))


class Role(Base, RoleMixin):
    __tablename__ = 'role'
    id = Column(Integer(), primary_key=True)
    name = Column(String(80), unique=True)
    description = Column(String(255))


class UserLogin(Base, UserMixin):
    __tablename__ = 'user_login'
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
    id = Column(Integer(), primary_key=True)
    frontend_state = Column(JSON())
    user_login_id = Column(Integer, ForeignKey('user_login.id'))


class Oer(Base):
    __tablename__ = 'oer'
    id = Column(Integer(), primary_key=True)
    url = Column(String(255), unique=True, nullable=False)
    data = Column(JSON())

    def __init__(self, url, data):
        self.url = url
        self.data = data

    def data_and_id(self):
        result = {**self.data}
        result['id'] = self.id
        return result


class WikichunkEnrichment(Base):
    __tablename__ = 'wikichunk_enrichment'
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
        self.created_at = datetime.now()
