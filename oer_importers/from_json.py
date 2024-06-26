import sys
import os
import json
import argparse

from datetime import datetime

from sqlalchemy import DateTime, create_engine, Column, Integer, String, JSON
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

from requests import get
from bs4 import BeautifulSoup, SoupStrainer
import re
import time

# For relative imports to work in Python 3.6
sys.path.append(os.path.dirname(os.path.realpath(__file__)))

from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET
from x5learn_server.db.database import Base, get_or_create_db
db_session = get_or_create_db(DB_ENGINE_URI)
from x5learn_server.models import Oer



###########################################################
# MAIN SCRIPT
###########################################################


def create_oer(data):
    oer = Oer(url, data)
    db_session.add(oer)
    db_session.commit()
    return True


if __name__ == '__main__':
    parser=argparse.ArgumentParser(
        description='''X5Learn import script for scraped OER data in JSON format.''',
        epilog="""NB existing oers won't be overwritten.""")
    parser.add_argument('filepath', type=str, help='JSON file containing OER data, i.e. url, title, description, etc')
    args=parser.parse_args()

    skipped = []
    succeeded_at_first_try = []
    succeeded_at_second_try = []
    failed = []

    with open(args.filepath) as json_file:
        rows = json.load(json_file)
    # print(type(data))
    # print(data)
    # raise

    for row in rows:
        print('\n______________________________________________________________')
        url = row['url']
        print(url)
        oer = db_session.query(Oer).filter_by(url=url).first()
        if oer is not None:
            print('Exists already -> skipping.')
            # db_session.delete(oer)
            # db_session.commit()
            skipped.append(url)
        elif create_oer(row):
            succeeded_at_first_try.append(url)
        elif create_oer(row):
            succeeded_at_second_try.append(url)
        else:
            print('Giving up.')
            failed.append(url)

    print(len(rows), 'URLs processed.\n')

    print(len(skipped), 'OERs skipped.')
    print(len(succeeded_at_first_try), 'OERs succeeded at first try.')
    print(len(succeeded_at_second_try), 'OERs succeeded at second try.')
    print(len(failed), 'OERs failed.')
    print()
    # for row in rows:
    #     url = row['url']
    #     print("    '"+url+"',")
