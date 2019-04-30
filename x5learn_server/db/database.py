from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker
from sqlalchemy.ext.declarative import declarative_base

from x5learn_server._config import ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_ROLE_NAME, ROLES

engine = None
db_session = None

Base = None


def get_or_create_session_db(db_engine_uri):
    """creates a singleton session db instance for user session management

    Args:
        db_engine_uri (str):
    """
    global engine
    global db_session

    global Base

    if engine is None:
        engine = create_engine(db_engine_uri, convert_unicode=True)
        db_session = scoped_session(sessionmaker(autocommit=False, autoflush=False, bind=engine))

        Base = declarative_base()
        Base.query = db_session.query_property()


def init_db():
    # import all modules here that might define models so that
    # they will be registered properly on the metadata.  Otherwise
    # you will have to import them first before calling init_db()
    global Base
    global engine

    import x5learn_server.models
    Base.metadata.create_all(bind=engine)


def initiate_login_table_and_admin_profile(user_datastore):
    init_db()

    # create roles
    for role in ROLES:
        user_datastore.find_or_create_role(id=int(role["id"]), name=role["name"], description=role["description"])

    # create admin user
    # if not user_datastore.find_user(email=ADMIN_EMAIL):
    #     user_datastore.create_user(email=ADMIN_EMAIL, password=ADMIN_PASSWORD)

    db_session.commit()

    # assign admin privileges to admin
    # user_datastore.add_role_to_user(ADMIN_EMAIL, ADMIN_ROLE_NAME)
    # db_session.commit()
