# database related configs
import os

db_user = os.environ["X5LEARN_DB_USERNAME"]
db_pass = os.environ["X5LEARN_DB_PASSWORD"]

DB_ENGINE_URI = 'postgresql://{}:{}@localhost:5432/x5learn'.format(db_user, db_pass)

#  admin credentials used to create a super user
ADMIN_EMAIL = "admin@x5learn.x5gon.org"
ADMIN_PASSWORD = "admin"

# Role descriptions
ADMIN_ROLE_NAME = "admin"
LEARNER_ROLE_NAME = "learner"

ROLES = [
    {"id": 0, "name": ADMIN_ROLE_NAME, "description": "Super user with administrative privileges"},
    {"id": 1, "name": LEARNER_ROLE_NAME, "description": "Learner with functions to enable learning"}
]
