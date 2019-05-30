from x5learn_server.db.database import Base
from flask_security import UserMixin, RoleMixin
from sqlalchemy.orm import relationship, backref
from sqlalchemy import Boolean, DateTime, Column, Integer, \
    Text, String, JSON, Float, ForeignKey, Table


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


# class OersChunks(Base):
#     __tablename__ = 'oers_chunks'
#     id = Column(Integer(), primary_key=True)
#     oer_id = Column('oer_id', Integer(), ForeignKey('oer.id'))
#     chunk_id = Column('chunk_id', Integer(), ForeignKey('chunk.id'))


# good post on cascade: https://stackoverflow.com/a/38770040/2237986

class Oer(Base):
    __tablename__ = 'oer'
    id = Column(Integer(), primary_key=True)
    url = Column(String(255), unique=True, nullable=False)
    data = Column(JSON())
    origin = Column(String(255))
    x5gon_material_id = Column(Integer())
    youtube_video_id = Column(String(255))
    chunks = relationship('Chunk', backref='oer', passive_deletes=True)

    def __init__(self, url, data, origin, x5gon_material_id, youtube_video_id):
        self.url = url
        self.data = data
        self.origin = origin
        self.x5gon_material_id = x5gon_material_id
        self.youtube_video_id = youtube_video_id


chunks_topics = Table('chunks_topics_association', Base.metadata,
    Column('chunk_id', Integer, ForeignKey('chunk.id', ondelete='CASCADE')),
    Column('topic_id', Integer, ForeignKey('topic.id', ondelete='CASCADE'))
)


class Chunk(Base):
    __tablename__ = 'chunk'
    id = Column(Integer(), primary_key=True)
    start = Column(Float())
    length = Column(Float())
    text = Column(Text())
    oer_id = Column(Integer, ForeignKey('oer.id', ondelete='CASCADE'), nullable=False)
    topics = relationship('Topic', secondary = chunks_topics, backref=backref('chunks', passive_deletes=True), passive_deletes=True)

    def __init__(self, start, length, text):
        self.start = start
        self.length = length
        self.text = text


class Topic(Base):
    __tablename__ = 'topic'
    id = Column(Integer(), primary_key=True)
    wikidata_item = Column(String(10))
    title = Column(String(255))
    url = Column(String(255), unique=True)

    def __init__(self, wikidata_item, title, url):
        self.wikidata_item = wikidata_item
        self.title = title
        self.url = url
