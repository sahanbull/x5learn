from flask import Flask
from flask_mail import Mail
from flask_security import Security, login_required, SQLAlchemySessionUserDatastore

# instantiate the user management db classes
from db.database import get_or_create_session_db
from server._config import DB_ENGINE_URI

get_or_create_session_db(DB_ENGINE_URI)

from db.database import db_session

from models import UserLogin, Role

# Create app
app = Flask(__name__)
mail = Mail()

app.config['DEBUG'] = True
app.config['SECRET_KEY'] = 'super-secret'
app.config['SECURITY_PASSWORD_HASH'] = "plaintext"

# user registration configs
app.config['SECURITY_REGISTERABLE'] = True
app.config['SECURITY_REGISTER_URL'] = '/register'
app.config['SECURITY_SEND_REGISTER_EMAIL'] = False

# user password configs
app.config['SECURITY_CHANGEABLE'] = True
app.config['SECURITY_CHANGE_URL'] = '/password_change'
app.config['SECURITY_SEND_PASSWORD_CHANGE_EMAIL'] = False


# Setup Flask-Security
user_datastore = SQLAlchemySessionUserDatastore(db_session,
                                                UserLogin, Role)

security = Security(app, user_datastore)
mail.init_app(app)


# create database when starting the app
@app.before_first_request
def initiate_login_db():
    from db.database import initiate_login_table_and_admin_profile
    initiate_login_table_and_admin_profile(user_datastore)

# Views
@app.route('/')
@login_required
def home():
    return 'Here you go!'

if __name__ == '__main__':
    app.run()
