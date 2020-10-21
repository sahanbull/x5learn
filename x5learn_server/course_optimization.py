import requests
import json

from x5learn_server.db.database import db_session
from x5learn_server.models import Oer


def convert_to_oer_ids(material_ids):
    result = []
    for material_id in material_ids:
        oer = find_oer_by_material_id(material_id)
        if oer is not None:
            print('convert', material_id, '->', oer.id, '=', oer.data['material_id'])
            result.append(oer.id)
    return result


def optimize_course(oer_ids):
    # API base url
    API_URL = "https://wp3dev.x5gon.org"

    # setup appropriate headers
    HEADERS = {
        'accept': 'application/json',
        'Content-Type': 'application/json',
    }

    # endpoint
    ENDPOINT = '/sequencing/sort'

    material_ids = convert_to_material_ids(oer_ids)

    data = {'basket': material_ids}
    response = requests.post(API_URL + ENDPOINT,
                         headers= HEADERS,
                         data=json.dumps(data))
    response_json = response.json()

    new_material_ids = response_json.get('output', {}).get('sequence', [])
    new_oer_ids = convert_to_oer_ids(new_material_ids)
    return new_oer_ids


def convert_to_material_ids(oer_ids):
    result = []
    for oer_id in oer_ids:
        oer = Oer.query.get(oer_id)
        if oer is not None:
            result.append(int(oer.data['material_id']))
    return result


def get_material_id(oer_id):
    oer = Oer.query.get(oer_id)
    if oer is None:
        return None
    return int(oer.data['material_id'])


def find_oer_by_material_id(material_id):
    return Oer.query.filter(Oer.data['material_id'].astext == str(material_id)).order_by(Oer.id.desc()).first()
