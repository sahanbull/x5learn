import os
import sqlalchemy as db
import json

DB_USER = os.environ["X5LEARN_DB_USERNAME"]
DB_PASS = os.environ["X5LEARN_DB_PASSWORD"]
DB_NAME = os.environ["X5LEARN_DB_NAME"]

THUMBPATH = os.environ.get("X5LEARN_THUMB_PATH")


def main():
    print("X5learn - back filling thumb paths to existing oer data...")

    oers, connection = get_oer_db_object()
    
    count = 0
    # iterate file in thumb folder
    for thumb in os.listdir(THUMBPATH):

        if not thumb.endswith(".jpg"):
            continue

        # extract oer id from file name
        oer_id = extract_oer_id(thumb)

        if oer_id == 0:
            continue
        
        # fetch db record based on oer id
        query = db.select([oers.columns.data]).where(oers.columns.id == oer_id)
        oer_data = connection.execute(query).fetchone()[0]

        if 'images' not in oer_data:
            oer_data['images'] = []

        if thumb in oer_data['images']:
            continue

        print("\n updating oer id :", oer_id)
        # update db record
        oer_data['images'].append(thumb)
        query = db.update(oers).values(data=oer_data)
        query = query.where(oers.columns.id == oer_id)
        connection.execute(query)
        count += 1

    print("\nEnding script. No of records updated : ", count)
        


def get_oer_db_object():
    db_engine_uri = 'postgresql://{}:{}@localhost:5432/{}'.format(
        DB_USER, DB_PASS, DB_NAME)
    engine = db.create_engine(db_engine_uri)
    connection = engine.connect()
    metadata = db.MetaData()
    oers = db.Table('oer', metadata, autoload=True, autoload_with=engine)

    return oers, connection


def extract_oer_id(thumb):
    try:
        return int(thumb[3:(thumb[3:].rfind("_") + 3)])
    except ValueError:
        return 0


if __name__ == '__main__':
    main()