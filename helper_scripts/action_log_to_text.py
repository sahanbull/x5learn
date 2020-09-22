import os
import sqlalchemy as db
from datetime import datetime
import time
import csv

def main(args):
    print("X5learn - Creating text file based on action log...")

    db_objects = get_db_objects(args["dbuser"], args["dbpass"], args["dbname"])
    actions = db_objects[0]
    users = db_objects[1]
    connection = db_objects[2]

    query = db.select([users.c.id, users.c.email]).where(users.c.email.like("p%")).order_by(users.c.id)
    user_data = connection.execute(query).fetchall()

    # list to hold session logs
    all_sessions_data = list()
    all_sessions_data.append(["Pid", "Datetime", "Task", "Duration", "ContentFlow Bar State", "Forced Complete Event"])

    # user lookup to find out user by id
    user_dict = dict()
    for user in user_data:
        user_dict[user.id] = user.email

    count = 0
    # fetching data user wise
    for id in user_dict.keys():
        if user_dict[id] == "p0":
            continue

        query = db.select([actions.columns.created_at, actions.columns.events, actions.columns.user_login_id]).where(actions.columns.user_login_id == id).order_by(actions.columns.client_time)
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

        # holds a single session
        session_data = list()

        for action in action_data:

            for event in action.events:

                write_string = ""
                if event['eventType'] == "StartTask":

                    if "".join(event['args']) != 'Task:ClimateChange' and "".join(event['args']) != 'Task:MachineLearning':
                        continue

                    # if task has not been logged completed force event based on last action
                    if last_session > 0:
                        durationInSeconds = last_action - last_session

                        write_string += datetime.utcfromtimestamp(last_action).strftime("%Y-%m-%d %H:%M:%S")
                        #write_string += " User - " + user_dict[action.user_login_id]
                        write_string += " Completed Task | Total Duration - " + time.strftime('%H:%M:%S', time.gmtime(durationInSeconds))
                        write_string += " | Content Flow State - " + last_content_flow_state
                        write_string += "\n\n"

                        if len(session_data) > 0:
                            session_data.append(time.strftime('%H:%M:%S', time.gmtime(durationInSeconds)))
                            session_data.append(last_content_flow_state)
                            session_data.append("Yes")
                            all_sessions_data.append(session_data)
                            session_data = list()

                    temp_date_string = datetime.utcfromtimestamp(int(event['clientTime'][:10])).strftime("%Y-%m-%d %H:%M:%S")
                    write_string += temp_date_string
                    # write_string += " User - " + user_dict[action.user_login_id]
                    write_string += " Started Task - " + "".join(event['args'])
                    write_string += " | Content Flow State - " + last_content_flow_state

                    session_data.append(user_dict[id])
                    session_data.append(temp_date_string)
                    session_data.append("".join(event['args']))

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

                    if len(session_data) > 0:
                        session_data.append(time.strftime('%H:%M:%S', time.gmtime(durationInSeconds)))
                        session_data.append(last_content_flow_state)
                        session_data.append("No")
                        all_sessions_data.append(session_data)
                        session_data = list()

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

        # writing data to a csv file
        if len(all_sessions_data) > 0:
            with open(write_path + "processed-logs.csv", 'w', newline='') as file:
                writer = csv.writer(file)

                for session in all_sessions_data:
                    writer.writerow(session)

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
    

def seconds_to_time_string(seconds):
    return seconds
    seconds = int(float(seconds))
    duration = str(int(seconds / 60)) + ':' + str(seconds % 60).zfill(2)
    return duration

def get_db_objects(user, passwd, db_name):
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
