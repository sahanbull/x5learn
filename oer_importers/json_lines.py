import sys
import os
import json
import argparse

from datetime import datetime

from sqlalchemy import DateTime, create_engine, Column, Integer, String, JSON
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# For relative imports to work in Python 3.6
sys.path.append(os.path.dirname(os.path.realpath(__file__)))

from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET
from x5learn_server.db.database import Base, get_or_create_db
db_session = get_or_create_db(DB_ENGINE_URI)
from x5learn_server.models import Oer



###########################################################
# JSON LINES OER IMPORTER
###########################################################

def import_oer_from_json(data):
    url = data['url']
    oer = Oer.query.filter_by(url=url).first()
    if oer is None:
        print('Adding OER', url)
        oer = Oer(url, data)
        db_session.add(oer)
        db_session.commit()
        return True
    return False



if __name__ == '__main__':
    parser=argparse.ArgumentParser(
        description='''X5Learn import script for OER using JSON lines. ''',
        epilog="""NB OERs with identical URLs won't be overwritten.""")
    parser.add_argument('filename', type=str, help='JSON lines file containing one OER per row, e.g. oers.jsonl - see http://jsonlines.org/')
    args=parser.parse_args()
    lines = open(args.filename).readlines()
    count = 0
    for line in lines:
        if import_oer_from_json(json.loads(line)):
            count += 1
    print(count, 'OERs added.\n')
