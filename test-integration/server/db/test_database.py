from flask import Flask
from flask_security import SQLAlchemySessionUserDatastore, Security

from x5learn_server.db.database import get_or_create_session_db

TEST_DB_URI = 'sqlite:////home/in4maniac/Documents/Code/x5gon_project/databases/x5learn_test.db'

def test_initiate_login_table_and_admin_profile():
    get_or_create_session_db(TEST_DB_URI)

    from x5learn_server.models import UserLogin, Role
    from x5learn_server.db.database import db_session, initiate_login_table_and_admin_profile


    app = Flask(__name__)
    app.config['DEBUG'] = True
    app.config['SECRET_KEY'] = 'super-secret'
    app.config['SECURITY_PASSWORD_HASH'] = "plaintext"

    # Setup Flask-Security
    user_datastore = SQLAlchemySessionUserDatastore(db_session,
                                                    UserLogin, Role)

    security = Security(app, user_datastore)

    initiate_login_table_and_admin_profile(user_datastore)