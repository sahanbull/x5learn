import os
import sqlalchemy as db
from datetime import datetime
import time
import csv
import json

def main(args):
    print("X5learn - Creating text file based on action log...")

    db_objects = get_db_objects(args["dbuser"], args["dbpass"], args["dbname"])
    actions = db_objects[0]
    predefined_actions = db_objects[1]
    users = db_objects[2]
    action_types = db_objects[3]
    connection = db_objects[4]

    query = db.select([users.c.id, users.c.email]).where(users.c.email.like("p%")).order_by(users.c.id)
    user_data = connection.execute(query).fetchall()

    # user lookup to find out user by id
    user_dict = dict()
    for user in user_data:
        user_dict[user.id] = user.email

    query = db.select([action_types.c.id, action_types.c.description])
    action_type_data = connection.execute(query).fetchall()

    # action type lookup to find out action type by id
    action_type_dict = dict()
    for action_type in action_type_data:
        action_type_dict[action_type.id] = action_type.description

    count = 0

    # open text file for writing user wise
    write_path = args['savepath'] if args['savepath'] is not None else "/tmp/"
    f = open(write_path + "ui-logs.jsonl", "a")
    f.truncate(0)

    query = db.select([actions.columns.created_at, actions.columns.events, actions.columns.user_login_id]).order_by(actions.columns.client_time)
    action_data = connection.execute(query).fetchall()

    for action in action_data:

        for event in action.events:

            write_object = dict()

            try:
                temp_time = datetime.utcfromtimestamp(int(event['clientTime'][:10])).strftime("%Y-%m-%d %H:%M:%S")
            except ValueError:
                temp_time = " - "

            try:
                temp_user = user_dict[action.user_login_id]
            except KeyError:
                temp_user = " - "
            
            write_object['time'] = temp_time
            write_object['user'] = temp_user
            write_object['action'] = event['eventType']
            write_object['args'] = event['args']

            if write_object is not None:
                f.write(json.dumps(write_object) + "\n")

            count += 1

    f.close()

    f = open(write_path + "action-logs.jsonl", "a")
    f.truncate(0)

    query = db.select([predefined_actions.columns.created_at, predefined_actions.columns.action_type_id, predefined_actions.columns.user_login_id, predefined_actions.columns.params]).order_by(predefined_actions.columns.created_at)
    predefined_action_data = connection.execute(query).fetchall()

    for action in predefined_action_data:
        write_object = dict()

        try:
            temp_user = user_dict[action.user_login_id]
        except KeyError:
            temp_user = " - "

        write_object['time'] = action.created_at.strftime("%Y-%m-%d %H:%M:%S")
        write_object['user'] = temp_user
        write_object['action'] = action_type_dict[action.action_type_id]
        write_object['args'] = action.params

        if write_object is not None:
            f.write(json.dumps(write_object) + "\n")

        count += 1

    f.close()

    print("Ending script. No of events processed : ", count)
    

def get_db_objects(user, passwd, db_name):
    db_engine_uri = 'postgresql://{}:{}@localhost:5432/{}'.format(
        user, passwd, db_name)
    engine = db.create_engine(db_engine_uri)
    connection = engine.connect()
    metadata = db.MetaData()

    predefined_actions = db.Table('action', metadata, autoload=True, autoload_with=engine)
    actions = db.Table('ui_log_batch', metadata, autoload=True, autoload_with=engine)
    users = db.Table('user_login', metadata, autoload=True, autoload_with=engine)
    action_types = db.Table('action_type', metadata, autoload=True, autoload_with=engine)

    return [actions, predefined_actions, users, action_types, connection]

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='actions to text file')
    parser.add_argument('--dbuser', required=True, type=str, help='username to connect to database')
    parser.add_argument('--dbpass', required=True, type=str, help='password to connect to database')
    parser.add_argument('--dbname', required=True, type=str, help='database name to connect to')
    parser.add_argument('--savepath', required=True, type=str, help='full path to folder where json files will be saved')
    args = vars(parser.parse_args())

    main(args)
