import os
import sqlalchemy as db
from datetime import datetime
import time

def main(args):
    print("X5learn - Creating text file based on action log...")

    db_objects = ge_db_objects(args["dbuser"], args["dbpass"], args["dbname"])
    actions = db_objects[0]
    users = db_objects[1]
    connection = db_objects[2]

    query = db.select([users.c.id, users.c.email]).where(users.c.email.like("p%"))
    user_data = connection.execute(query).fetchall()

    # user lookup to find out user by id
    user_dict = dict()
    for user in user_data:
        user_dict[user.id] = user.email

    count = 0
    # fetching data user wise
    for id in user_dict.keys():
        query = db.select([actions.columns.created_at, actions.columns.events, actions.columns.user_login_id]).where(actions.columns.user_login_id == id)
        action_data = connection.execute(query).fetchall()

        # open text file for writing user wise
        write_path = args['savepath'] if args['savepath'] is not None else "/tmp/"
        f = open(write_path + "processed-logs-{}.txt".format(user_dict[id]), "a")
        f.truncate(0)
        f.write("UI Log for User - {} \n\n".format(user_dict[id]))

        # holds timestamp of previous instance where 'start task' was executed
        last_session = -1

        # holds timestamp of last action
        last_action = 0

        # holds timestamp of previous instance where 'Toggle content flow bar' was executed
        last_content_flow_toggle = 0

        # holds last state of content flow
        last_content_flow_state = find_initial_content_flow_state(action_data)

        for action in action_data:

            for event in action.events:

                write_string = ""
                if event['eventType'] == "StartTask":

                    # if task has not been logged completed force event based on last action
                    if last_session > 0:
                        durationInSeconds = last_action - last_session

                        write_string += datetime.utcfromtimestamp(last_action).strftime("%Y-%m-%d %H:%M:%S")
                        #write_string += " User - " + user_dict[action.user_login_id]
                        write_string += " Completed Task | Total Duration - " + time.strftime('%H:%M:%S', time.gmtime(durationInSeconds))
                        write_string += " | Content Flow State - " + last_content_flow_state
                        write_string += "\n\n"

                    write_string += datetime.utcfromtimestamp(int(event['clientTime'][:10])).strftime("%Y-%m-%d %H:%M:%S")
                    #write_string += " User - " + user_dict[action.user_login_id]
                    write_string += " Started Task - " + "".join(event['args'])
                    write_string += " | Content Flow State - " + last_content_flow_state

                    last_session = int(event['clientTime'][:10])

                elif event['eventType'] == "CompleteTask":
                    durationInSeconds = 0
                    if last_session != 0 and last_session < int(event['clientTime'][:10]):
                        durationInSeconds = (int(event['clientTime'][:10]) - last_session)
                        last_session = 0

                    write_string += datetime.utcfromtimestamp(int(event['clientTime'][:10])).strftime("%Y-%m-%d %H:%M:%S")
                    #write_string += " User - " + user_dict[action.user_login_id]
                    write_string += " Completed Task | Duration - " + time.strftime('%H:%M:%S', time.gmtime(durationInSeconds))
                    write_string += " | Content Flow State - " + last_content_flow_state
                    write_string += "\n"

                elif event['eventType'] == "ToggleContentFlow":
                    durationInSeconds = 0
                    if last_content_flow_toggle != 0 and last_content_flow_toggle < int(event['clientTime'][:10]):
                        durationInSeconds = (int(event['clientTime'][:10]) - last_content_flow_toggle)

                    write_string += datetime.utcfromtimestamp(int(event['clientTime'][:10])).strftime("%Y-%m-%d %H:%M:%S")
                    #write_string += " User - " + user_dict[action.user_login_id]
                    write_string += " Toggled Content Flow - " + "".join(event['args'])
                    write_string += " | Duration (Since Last Toggle) - " + time.strftime('%H:%M:%S', time.gmtime(durationInSeconds))

                    last_content_flow_state = event['args'][0]
                    last_content_flow_toggle = int(event['clientTime'][:10])

                if write_string != "":
                    f.write(write_string + "\n")

                count += 1

                try:
                    if last_content_flow_toggle == 0:
                        last_content_flow_toggle = int(event['clientTime'][:10])

                    last_action = int(event['clientTime'][:10])
                except ValueError:
                    continue

        f.close()

    print("\nEnding script. No of events processed : ", count)


def find_initial_content_flow_state(action_data):
    initial_state = None
    for action in action_data:
        if initial_state is not None:
            break

        for event in action.events:
            if initial_state is not None:
                break

            if event['eventType'] == "ToggleContentFlow":
                initial_state = 'enabled' if event['args'][0] == "disabled" else 'disabled'
    
    return initial_state if initial_state is not None else "disabled"
    

def ge_db_objects(user, passwd, db_name):
    db_engine_uri = 'postgresql://{}:{}@localhost:5432/{}'.format(
        user, passwd, db_name)
    engine = db.create_engine(db_engine_uri)
    connection = engine.connect()
    metadata = db.MetaData()
    actions = db.Table('ui_log_batch', metadata, autoload=True, autoload_with=engine)
    users = db.Table('user_login', metadata, autoload=True, autoload_with=engine)

    return [actions, users, connection]

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='actions to text file')
    parser.add_argument('--dbuser', required=True, type=str, help='username to connect to database')
    parser.add_argument('--dbpass', required=True, type=str, help='password to connect to database')
    parser.add_argument('--dbname', required=True, type=str, help='database name to connect to')
    parser.add_argument('--savepath', required=True, type=str, help='full path to save text file')
    args = vars(parser.parse_args())

    main(args)
