import os, json
import sqlalchemy as db


def main(args):
    print("X5learn - creating oers based on youtube json...\n")

    # validate json file
    json_file_path = args["jsonpath"]
    if not os.path.exists(json_file_path):
        print("Invalid json file")
        return

    # extract json data from file
    file = open(json_file_path)
    json_data = json.load(file)
    file.close()

    # create database connection and get oer object
    oers, db_engine = get_oer_db_object(args["dbuser"], args["dbpass"], args["dbname"])

    count = 0
    # iterate json
    for index, value in enumerate(json_data):

        print('processing ' + value['video_url'])

        # check if url already exist in oer
        if db_engine.scalar(oers.count().where(oers.columns.url == value['video_url'])):
            continue

        # create oer and save to database
        oer_data = create_oer_data(value)
        ins = oers.insert()
        db_engine.execute(ins, url=value['video_url'], data=oer_data)

        print('\noer record for url ' + value['video_url'] + ' successfully created')
        count += 1

    print("\n" + str(count) + " inserted")
    print("X5learn - ending script")


def create_oer_data(json_data):
    oer_data = dict()
    oer_data['url'] = json_data['video_url']
    oer_data['material_id'] = 0
    oer_data['title'] = json_data['title']
    oer_data['provider'] = "youtube.com"
    oer_data['description'] = json_data['description']
    oer_data['date'] = json_data['publishedAt'].split("T")[0]
    oer_data['images'] = []
    oer_data['duration'] = time_from_youtube_timestring(json_data['duration'])
    oer_data['mediatype'] = "video"
    oer_data['translations'] = {}
    oer_data['durationInSeconds'] = second_from_timestring(json_data['duration'])
    oer_data['transcript'] = json_data['transcripts']

    return oer_data


def get_oer_db_object(user, passwd, db_name):
    db_engine_uri = 'postgresql://{}:{}@localhost:5432/{}'.format(
        user, passwd, db_name)
    db_engine = db.create_engine(db_engine_uri)
    db_engine = db_engine.connect()
    metadata = db.MetaData()
    oers = db.Table('oer', metadata, autoload=True, autoload_with=db_engine)

    return oers, db_engine


def time_from_youtube_timestring(youtubetime):
    timestring = str(youtubetime.split("M")[0])[2:]
    timestring += ":"
    timestring += str(youtubetime.split("M")[1].split("S")[0])
    return timestring


def second_from_timestring(timestring):
    seconds = int(str(timestring.split('M')[0])[2:]) * 60 + int(timestring.split('M')[1].split('S')[0])
    return seconds


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Creates oer records in database based on a json file containaing youtube data')
    parser.add_argument('--dbuser', required=True, type=str, help='username to connect to database')
    parser.add_argument('--dbpass', required=True, type=str, help='password to connect to database')
    parser.add_argument('--dbname', required=True, type=str, help='database name to connect to')
    parser.add_argument('--jsonpath', required=True, type=str, help='full path to json file')
    args = vars(parser.parse_args())

    main(args)