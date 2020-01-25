# database related configs
import os

print(os.environ)

db_user = os.environ["X5LEARN_DB_USERNAME"]
db_pass = os.environ["X5LEARN_DB_PASSWORD"]
db_name = os.environ["X5LEARN_DB_NAME"]

DB_ENGINE_URI = 'postgresql://{}:{}@localhost:5432/{}'.format(
    db_user, db_pass, db_name)

#  admin credentials used to create a super user
ADMIN_EMAIL = "admin@x5learn.x5gon.org"
ADMIN_PASSWORD = "admin"

# Role descriptions
ADMIN_ROLE_NAME = "admin"
LEARNER_ROLE_NAME = "learner"

PASSWORD_SECRET = 'kFGnOO0J8vhT2wlSZ4ti'

ROLES = [
    {"id": 0, "name": ADMIN_ROLE_NAME,
     "description": "Super user with administrative privileges"},
    {"id": 1, "name": LEARNER_ROLE_NAME,
     "description": "Learner with functions to enable learning"}
]

# Version for x5learn api
LATEST_API_VERSION = "0.1"

# Mail server configuration
MAIL_SENDER = os.environ["X5LEARN_MAIL_SENDER"]
MAIL_USERNAME = os.environ["X5LEARN_MAIL_USERNAME"]
MAIL_PASS = os.environ["X5LEARN_MAIL_PASS"]
MAIL_SERVER = os.environ["X5LEARN_MAIL_SERVER"]
MAIL_PORT = int(os.environ["X5LEARN_MAIL_PORT"])

# Getting server name
SERVER_NAME = os.environ.get("SERVER_NAME") or "145.14.12.67:6001"
