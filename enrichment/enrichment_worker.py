import os, requests, re, json, itertools

from time import sleep
from collections import defaultdict

from langdetect import detect_langs

from wikichunkifiers.pdf import extract_chunks_from_pdf
from wikichunkifiers.generic import extract_chunks_from_generic_text
from wikichunkifiers.video import extract_chunks_from_x5gon_video
from wikichunkifiers.lib.util import EnrichmentError

import wikipedia

from preview_generator.manager import PreviewManager
from wand.image import Image
import wget
import urllib

API_ROOT = os.environ.get("FLASK_API_ROOT")

THUMBPATH = os.environ.get("X5LEARN_THUMB_PATH")
TEMPPATH = "/tmp/"
SUPPORTED_FILE_FORMATS = ['mp4', 'mov', 'webm', 'ogv', "pdf","mp3"]
THUMB_WIDTH = 332
THUMB_HEIGHT = 175


# API_ROOT = 'http://127.0.0.1:5000/api/v1/'


def main(args):
    if args["mode"] == "wiki":
        """ Runs every 5 seconds to get the pending enrichment tasks and runs them to enrich them.
        """
        say('hello')
        while (True):
            try:
                # get oer record of the most recent requested materials
                r = requests.post(API_ROOT + "most_urgent_unstarted_enrichment_task/", data={})
                # get json obj with (url, material data)
                j = json.loads(r.text)
                # if there is additional data in j
                if 'data' in j:
                    oer_data = j['data']
                    url = oer_data['url']
                    enrichment_data, error = make_enrichment_data(oer_data)
                    post_back_wikichunks(url, enrichment_data, error if error is None else error[:255])
                    if error is None:
                        print('NO ERRORS')
                    else:
                        print('ERROR:', error)
                elif 'info' in j:
                    say(j['info'])
                    sleep(2)
                else:
                    say('Response is missing essential fields')
                    sleep(60)
            except requests.exceptions.ConnectionError:
                say('ConnectionError caught - waiting for main app to respond.')
                sleep(5)
            except Exception as err:
                print("\nError : {0}".format(err))
                say('Something went wrong. Waiting.')
                sleep(5)
    elif args["mode"] == "thumb":
        """ Runs every 5 seconds to get the pending thumbnail generation tasks and generates thumbnails.
        """
        say('hello')
        while (True):
            task = None
            try:
                # create directories
                create_directories()

                # get task of the most recent requested materials
                task = get_thumb_generation_task()
                if 'url' in task:

                    # get file details
                    file_name, file_extension = extract_file_name_and_type(task['url'])

                    # if file is audio set back default audio thumb
                    if file_extension == "mp3":
                        post_back_thumb_generation_result(task['url'], "tn_audio_332x175.jpg")
                        continue

                    # download file in a temporary folder for thumb generation
                    wget.download(urllib.parse.unquote(task['url']), out=TEMPPATH)

                    # init preview manager
                    manager = PreviewManager(THUMBPATH, create_folder=True)

                    if file_extension in SUPPORTED_FILE_FORMATS:
                        thumb_file_name = create_thumbnail(manager, file_name, task['oer_id'])
                        post_back_thumb_generation_result(task['url'], thumb_file_name)


                elif 'info' in task:
                    say(task['info'])
                    sleep(60)
                else:
                    say('Response is missing essential fields')
                    sleep(60)
            except requests.exceptions.ConnectionError:
                say('ConnectionError caught - waiting for main app to respond.')
                sleep(5)
            except Exception as err:
                error_string = str(err)
                if task is not None and 'url' in task:
                    post_back_thumb_generation_result(task['url'], None, error_string[:255])

                print("\nError : {0}".format(err))
                say('Something went wrong. Waiting.')
                sleep(5)
    else:
        print("Invalid argument for mode")

def say(text):
    print('X5Learn Enrichment Worker says:', text)


def make_enrichment_data(oer_data):
    """Generates wikifier enrichments for media. Gets the meta information and creates extracts chunks, mentions etc.

    Args:
        oer_data {key: val}: dict of meta information inc. url, title, desc and also material id if X5GON record

    Returns:

    """
    data = {'chunks': [], 'mentions': {}, 'clusters': [], 'errors': False}
    error = None
    try:
        data['chunks'] = make_wikichunks(oer_data)
        data['mentions'] = extract_mentions(data['chunks'])
        data['clusters'] = extract_concept_clusters(data['chunks'], data['mentions'])
    except EnrichmentError as err:
        error = err.message
        data['errors'] = True
        print('\nEnrichmentError', error)
    except Exception as err:
        error = str(err)
        data['errors'] = True
        print('\nException', error)
    return data, error


def make_wikichunks(oer_data):
    """extracts the text and also chunkifies it.

    Args:
        oer_data {key, val}: where they is url and oer data in a dict

    Returns:
        ([str]): a list of chunks
    """
    print(
        '\n________________________________________________________________________________________________________________________________')
    url = oer_data['url']
    print(url)
    print(oer_data['title'])
    # if the material is pdf:
    if url.lower().endswith('pdf'):
        return extract_chunks_from_pdf(url)
    if 'meetup.com/' in url:
        return extract_chunks_from_generic_text(url, oer_data)
    if url.lower().endswith('.mp4') and "material_id" in oer_data:  # if X5GON Video,
        try:
            return extract_chunks_from_x5gon_video(oer_data)
        except ValueError:
            pass

    raise EnrichmentError('Unsupported file format')


def extract_concept_clusters(chunks, mentions):
    print('\n_____________________________ Concept clusters')
    occurrences = defaultdict(int)
    for chunk in chunks:
        for entity in chunk['entities']:
            title = entity['title']
            if len(title) > 2 and entity[
                'id'] in mentions:  # Exclude titles that are too short, such as one-letter variable names
                occurrences[title] += 1
    titles = [x[0] for x in sorted(occurrences.items(), key=lambda k_v: k_v[1], reverse=True)[:5]]
    print('Titles:', titles)
    clusters = []

    for title in titles:
        try:
            links = wikipedia.page(title).links
        except Exception as err:
            links = []
            print('Ignoring error: ', err)
        links = [link for link in links if link in titles]
        cluster = [title] + links
        clusters.append(cluster)

    print('Raw:', clusters)
    clusters = merge_clusters(clusters)
    print('Merged:', clusters)
    return clusters


def extract_mentions(chunks):
    # print('\n_____________________________ Mentions')
    print('\nextracting mentions')
    mentions = {}
    entities = []
    for chunk in chunks:
        entities += chunk['entities']
    entities = list({v['id']: v for v in
                     entities}.values())  #  remove duplicates. solution adapted from https://stackoverflow.com/a/11092590/2237986
    entities = [e for e in entities if
                len(e['title']) > 1]  # exclude super-short titles, such as one-letter names of mathematical variables
    for entity in entities:
        entity_id = entity['id']
        title = entity['title'].lower()
        title = remove_stuff_in_parentheses(
            title)  # e.g. look for mentions of "strategy" if the concept is "strategy (game theory)"
        title = title.strip()
        for chunk in chunks:
            text = chunk['text']
            text = re.sub(r'\s+', ' ', text)
            positions = [m.start() for m in re.finditer(re.escape(title), text.lower())]
            prev_position = None
            for position in positions:
                position += int(
                    len(title) / 2)  # Focus on the middle of the title to account for variations in surrounding blanks
                if prev_position is not None and position - prev_position < 200 and not contains_end_mark(
                        text[prev_position:position]):  # ignore adjacent mentions as described in issue #167
                    continue
                prev_position = position
                sentence, pos_in_chunk = sentence_at_position(text, position)
                if len(sentence) > 200:  # probably not a normal sentence
                    sentence, pos_in_chunk = excerpt_at_position(text, position)
                if not looks_like_english(sentence):
                    continue
                position_in_resource = round(chunk['start'] + chunk['length'] * pos_in_chunk / len(text), 4)
                if entity_id not in mentions:  # could we use defaultdict for this? not sure if it works for lists. too lazy/rushed to check now.
                    mentions[entity_id] = []
                if len(mentions[entity_id]) == 0 or mentions[entity_id][-1][
                    'positionInResource'] != position_in_resource:  # don't create duplicates if an entity is mentioned twice in a sentence
                    mentions[entity_id].append({'sentence': sentence, 'positionInResource': position_in_resource})
    print(len(mentions), 'mentions found')
    return mentions


def contains_end_mark(text):
    return re.search(r'[.?!]', text)


def sentence_at_position(text, position):
    end_mark_positions = [m.start() for m in re.finditer('[.!?]([ ]|$)', text)]
    if len(end_mark_positions) == 0:
        return text, 0
    sentence_start_position = 0
    for end_mark_position in end_mark_positions:
        if end_mark_position > position:
            return text[sentence_start_position:(end_mark_position + 1)], sentence_start_position
        sentence_start_position = end_mark_position + 1
    return text[sentence_start_position:], sentence_start_position


def excerpt_at_position(text, position):
    start_pos = max(0, position - 70)
    end_pos = position + 80
    words = text[start_pos:end_pos].split(' ')
    excerpt = ' '.join(words[1:-1])
    return '…' + excerpt + '…', start_pos


def post_back_wikichunks(url, data, error):
    payload = {'url': url, 'data': data, 'error': error}
    r = requests.post(API_ROOT + "ingest_wikichunk_enrichment/", data=json.dumps(payload))
    # print('post_back_wikichunks', payload)


def looks_like_english(sentence):
    language = detect_langs(sentence)[0]
    return language.lang == 'en' and language.prob > 0.9


def remove_stuff_in_parentheses(text):
    return re.sub(r'\([^)]*\)', '', text)


def merge_clusters(raw_clusters):
    resulting_merged_clusters = []
    # print('raw_clusters', raw_clusters)
    for raw_cluster in raw_clusters:
        # print('raw_cluster', raw_cluster)
        overlapping_merged_clusters = [c for c in resulting_merged_clusters if not set(c).isdisjoint(set(raw_cluster))]
        # print('overlapping_merged_clusters', overlapping_merged_clusters)
        for o in overlapping_merged_clusters:
            resulting_merged_clusters.remove(o)
        merged_cluster = raw_cluster + list(itertools.chain(*overlapping_merged_clusters))
        # print("merged_cluster", merged_cluster)
        resulting_merged_clusters.append(unique_list_of_lists(merged_cluster))
        # print("without dupls:", merged_cluster)
    # print(resulting_merged_clusters)
    return resulting_merged_clusters


def unique_list_of_lists(k):  # https://stackoverflow.com/a/2213973/2237986
    k.sort()
    return list(k for k, _ in itertools.groupby(k))


def get_thumb_generation_task():
    r = requests.post(API_ROOT + "most_urgent_unstarted_thumb_generation_task/", data={})
    # get json obj with (url, material data)
    return json.loads(r.text)


def extract_file_name_and_type(url):
    file_name = url[url.rfind("/")+1:]
    file_extension = file_name[file_name.rfind(".")+1:]
    return file_name, file_extension


def create_directories():
    if not os.path.exists(THUMBPATH):
        os.mkdir(THUMBPATH)

    if not os.path.exists(TEMPPATH):
        os.mkdir(TEMPPATH)


def create_thumbnail(manager, file_name, oer_id):

    # create a thumb large enough to support cropping if needed
    path_to_preview = manager.get_jpeg_preview(
        TEMPPATH + file_name,
        height=800
    )

    # fill thumbnail based on width and crop if required
    with Image(filename=path_to_preview) as img:
        img_width = img.width
        img_height = img.height

        asepect_ratio = img_height / img_width
        height_based_on_aspect_ratio = round(332 * asepect_ratio)

        img.resize(332, height_based_on_aspect_ratio)

        #cropping image from top
        img.crop(0, 0, width=332, height=175)

        thumb_file_name = "tn_" + str(oer_id) + "_" + "332x175.jpg"
        img.save(filename=THUMBPATH + thumb_file_name)


    # removing temp files
    os.remove(path_to_preview)
    os.remove(TEMPPATH + file_name)

    return thumb_file_name


def post_back_thumb_generation_result(url, thumb_file_name, error=None):
    payload = {'url': url, 'thumb_file_name' : thumb_file_name, 'error': error}
    r = requests.post(API_ROOT + "ingest_thumb_generation_result/", data=json.dumps(payload))


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Enrich oers with wiki data or thumbnails')
    parser.add_argument('--mode', required=True, type=str, help='Mode should either be "wiki" or "thumb"')
    args = vars(parser.parse_args())

    main(args)
