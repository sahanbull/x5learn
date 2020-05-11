import os
import sqlalchemy as db


def main(args):
    print("X5learn - back filling thumb paths to existing oer data...")

    oers, connection = get_oer_db_object(args["dbuser"], args["dbpass"], args["dbname"])

    count = 0
    # iterate file in thumb folder
    for thumb in os.listdir(args["thumbpath"]):

        if thumb.startswith("tn_audio"):
            continue

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

        print("\n updating thumb path for oer id :", oer_id)
        # update db record
        oer_data['images'].append(thumb)
        query = db.update(oers).values(data=oer_data)
        query = query.where(oers.columns.id == oer_id)
        connection.execute(query)
        count += 1

    print("\nEnding script. No of records updated : ", count)


def get_oer_db_object(user, passwd, db_name):
    db_engine_uri = 'postgresql://{}:{}@localhost:5432/{}'.format(
        user, passwd, db_name)
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
    import argparse

    parser = argparse.ArgumentParser(description='Backfill oers with missing thumb paths')
    parser.add_argument('--dbuser', required=True, type=str, help='username to connect to database')
    parser.add_argument('--dbpass', required=True, type=str, help='password to connect to database')
    parser.add_argument('--dbname', required=True, type=str, help='database name to connect to')
    parser.add_argument('--thumbpath', required=True, type=str, help='full path to thumb folder')
    args = vars(parser.parse_args())

    main(args)
