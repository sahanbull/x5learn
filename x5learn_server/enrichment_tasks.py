# _ = get_or_create_db(DB_ENGINE_URI)
import sqlalchemy

from x5learn_server.db.database import db_session
from x5learn_server.models import Oer, WikichunkEnrichment, WikichunkEnrichmentTask, ThumbGenerationTask
from datetime import datetime, timedelta

CURRENT_ENRICHMENT_VERSION = 1
ENRICHMENT_VALIDITY_PERIOD_DAYS = 180


def push_enrichment_task_if_needed(url, urgency):
    # check if OER is already listed for enrichment
    enrichment = WikichunkEnrichment.query.filter_by(url=url).first()

    # if the enrichment is not present or outdated: push enrichment task
    if (enrichment is None) or (enrichment.version != CURRENT_ENRICHMENT_VERSION): 
        push_enrichment_task(url, urgency)
    elif (enrichment.last_update_at is None):
        push_enrichment_task(url, urgency)
    else:
        current_datetime = datetime.utcnow()
        enrichment_last_update_datetime = enrichment.last_update_at

        date_diff = current_datetime - enrichment_last_update_datetime

        if (date_diff.days >= ENRICHMENT_VALIDITY_PERIOD_DAYS):
            push_enrichment_task(url, urgency)


def push_enrichment_task(url, priority):
    # print('push_enrichment_task')
    try:
        # check if the url is currently put in the task queue
        task = WikichunkEnrichmentTask.query.filter_by(url=url).first()
        # if not a task, create task in the task queue
        if task is None:
            task = WikichunkEnrichmentTask(url, priority)
            db_session.add(task)
        else:
            # else increase priority
            task.priority += priority
        db_session.commit()
    except sqlalchemy.orm.exc.StaleDataError:
        print(
            'sqlalchemy.orm.exc.StaleDataError caught and ignored.')  # This error came up occasionally. I'm not 100% sure about what it entails but it didn't seem to affect the user experience so I'm suppressing it for now to prevent a pointless alert on the frontend. Grateful for any helpful tips. More information on this error: https://docs.sqlalchemy.org/en/13/orm/exceptions.html#sqlalchemy.orm.exc.StaleDataError


def save_enrichment(url, data):
    oer = Oer.query.filter_by(url=url).first()
    if oer is None:
        return
    data['oerId'] = oer.id
    enrichment = WikichunkEnrichment.query.filter_by(url=url).first()
    if enrichment is None:
        enrichment = WikichunkEnrichment(url, data, CURRENT_ENRICHMENT_VERSION, datetime.utcnow())
        db_session.add(enrichment)
    else:
        enrichment.data = data
        enrichment.version = CURRENT_ENRICHMENT_VERSION
        enrichment.last_update_at = datetime.utcnow()
    db_session.commit()


def push_thumbnail_generation_task(oer, priority):
    try:
        # check if the url is currently put in the task queue
        task = ThumbGenerationTask.query.filter_by(url=oer.url).first()
        # if not a task, create task in the task queue
        if task is None:
            thumb_data = {'oer_id': oer.id, 'retries': 0} if 'youtu' not in oer.url else {'oer_id': oer.id, 'retries': 0, 'yt_thumb' : "https://i.ytimg.com/vi/{}/hqdefault.jpg".format(oer.url.split("=")[1])}
            task = ThumbGenerationTask(oer.url, priority, thumb_data)
            db_session.add(task)
        else:
            # else increase priority
            task.priority += priority

        db_session.commit()
    except sqlalchemy.orm.exc.StaleDataError:
        print(
            'sqlalchemy.orm.exc.StaleDataError caught and ignored.')