# database related configs
import os

db_user = os.environ["X5LEARN_DB_USERNAME"]
db_pass = os.environ["X5LEARN_DB_PASSWORD"]
db_name = os.environ["X5LEARN_DB_NAME"]

DB_ENGINE_URI = 'postgresql://{}:{}@localhost:5432/{}'.format(db_user, db_pass, db_name)

#  admin credentials used to create a super user
ADMIN_EMAIL = "admin@x5learn.x5gon.org"
ADMIN_PASSWORD = "admin"

# Role descriptions
ADMIN_ROLE_NAME = "admin"
LEARNER_ROLE_NAME = "learner"

PASSWORD_SECRET = 'super-secret'

ROLES = [
    {"id": 0, "name": ADMIN_ROLE_NAME, "description": "Super user with administrative privileges"},
    {"id": 1, "name": LEARNER_ROLE_NAME, "description": "Learner with functions to enable learning"}
]

# Mail server configuration
MAIL_USERNAME = os.environ["X5LEARN_MAIL_USERNAME"]
MAIL_PASS = os.environ["X5LEARN_MAIL_PASS"]
MAIL_SERVER = os.environ["X5LEARN_MAIL_SERVER"]
MAIL_PORT = os.environ["X5LEARN_MAIL_PORT"]
