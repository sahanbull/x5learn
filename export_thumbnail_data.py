import os
import sys


from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET
from x5learn_server.db.database import Base, get_or_create_db
db_session = get_or_create_db(DB_ENGINE_URI)
from x5learn_server.models import Oer


# This is a temporary script that maps X5Learn thumbnail files to X5GON material ids
# As per request from our colleagues in Nantes
# https://x5gon-dev.slack.com/archives/DGK0UKPTP/p1576685316000200


for filename in os.listdir('/home/ucl/data/static/thumbs/'):
    x5learn_id = filename.split('_')[1]
    oer = Oer.query.filter_by(id=x5learn_id).first()
    if oer:
        print(x5learn_id, ',', filename, ',', oer.data['material_id'])
