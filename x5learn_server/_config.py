# database related configs
DB_ENGINE_URI = 'sqlite:////home/in4maniac/Documents/Code/x5gon_project/databases/x5learn_test.db'

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
