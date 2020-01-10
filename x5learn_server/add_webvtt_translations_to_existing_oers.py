from time import sleep
import json
import requests

from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET
from x5learn_server.db.database import Base, get_or_create_db
db_session = get_or_create_db(DB_ENGINE_URI)
from x5learn_server.models import Oer


# This background worker script keeps iterating over all the existing OERs
# in the X5Learn database, looking for missing translation data. When it finds
# an OER for which we haven't added webvtt translations yet, it requests them
# from the X5GON API.

# Specifically, the script looks for the "translations" field in the JSON part
# of the OER (oer.data).
# This field should be a dict, e.g. {"en": "Hello World", "de": "Hallo Welt"}
# If the field doesn't exist, it will be created by requesting webvtt data
# from the X5GON API.
# If the field exists, we assume that the OER has up-to-date translations.

# Running this script in the background will ensure that translations will
# eventually be fetched for all existing OERs and new OERs.
# This quick&dirty approach should do the trick for the purpose of showcasing
# the webvtt integration and the quality of X5GON translations.

# Note the following limitations:

# 1. Unlike WikichunkEnrichments, there is currently no mechanism for notifying
# the frontend of incoming data. If a translation isn't alreaady in our db at
# the time the user accesses an OER, then the translation will only become
# visible to the user after the user reloads the page (assuming that it ha
# finished processing by that time). By contrast, existing translations in the
# db are visible instantly when the user accesses the OER.

# 2. This script won't know if X5GON ever updates its translations. It simply
# sticks with the first result it retrieves and never checks for new versions.
# If we ever needed to refresh the results, a simple way to achieve this
# would be to delete the "translations" field from oer.data in all OERs.

# 3. While it's possible to run this script in parallel background threads
# (to speed up processing overall), it may occasionally produce redundant
# requests if multiple instances of the script ask for the same OER
# simultaneously. The cost of this is probably negligible but I though it's
# worth pointing out nevertheless.


PLATFORM_URL = 'https://platform.x5gon.org/api/v1'

def request_translations(oer):
    material_id = oer.data['material_id']
    print('Material id:', material_id)
    # get the list of contents relevant to this material
    url = "{}/oer_materials/{}/contents".format(PLATFORM_URL, material_id)
    contents = requests.get(url).json()
    translations = {}
    for content in contents["oer_contents"]:
        if content["type"] == "translation" and content["extension"] == "webvtt":
            language = content["language"]
            text = content["value"]["value"]
            translations[language] = text
    return translations


def check_db_for_missing_translations(force):
    print('Checking for missing translations...')
    for oer in Oer.query.all():
        if 'material_id' not in oer.data:
            continue # ignore any OERs that didn't come from X5GON
        if force or 'translations' not in oer.data:
            translations = request_translations(oer)
            if translations=={}:
                print('<no translations available>')
            else:
                print(' '.join([ k for k in translations.keys() ]))
            # copy the dict, see https://stackoverflow.com/a/53977819/2237986
            new_data = json.loads(json.dumps(oer.data))
            new_data['translations'] = translations
            oer.data = new_data
            db_session.commit()
            print()


def main(args):
    while(True):
        check_db_for_missing_translations(args['force'])
        sleep(3)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='USAGE: See sourcecode')
    parser.add_argument('--force', action='store_true', help='Request translations no matter what. Overwrite any existing translations')
    args = vars(parser.parse_args())
    main(args)
