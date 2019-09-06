# _ = get_or_create_db(DB_ENGINE_URI)
from x5learn_server.db.database import db_session
from x5learn_server.models import Oer, WikichunkEnrichment, WikichunkEnrichmentTask


CURRENT_ENRICHMENT_VERSION = 1


def push_enrichment_task_if_needed(url, urgency):
    enrichment = WikichunkEnrichment.query.filter_by(url=url).first()
    if (enrichment is None) or (enrichment.version != CURRENT_ENRICHMENT_VERSION):
        push_enrichment_task(url, urgency)


def push_enrichment_task(url, priority):
    # print('push_enrichment_task')
    try:
        task = WikichunkEnrichmentTask.query.filter_by(url=url).first()
        if task is None:
            task = WikichunkEnrichmentTask(url, priority)
            db_session.add(task)
        else:
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
        enrichment = WikichunkEnrichment(url, data, CURRENT_ENRICHMENT_VERSION)
        db_session.add(enrichment)
    else:
        enrichment.data = data
        enrichment.version = CURRENT_ENRICHMENT_VERSION
    db_session.commit()
