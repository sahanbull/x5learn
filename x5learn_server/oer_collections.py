import re, math, json

from x5learn_server.models import Oer, WikichunkEnrichment
from x5learn_server.enrichment_tasks import push_enrichment_task_if_needed
from x5learn_server.oer_collections_data import oer_collections

autocomplete_cache = {}


def search_in_oer_collections(collection_titles, text, max_n_results=0):
    # print('search_in_oer_collections', collection_titles)
    urls = []
    for collection_title in collection_titles:
        if collection_title in oer_collections:
            urls += oer_collections[collection_title]['video_urls']
    oers = Oer.query.filter(Oer.url.in_(urls)).order_by(Oer.id).all()
    # Exclude urls of missing oers
    urls = [ oer.url for oer in oers ]
    # Exclude duplicates
    urls = list(set(urls))
    relevance_scores_per_url = {}
    for enrichment in WikichunkEnrichment.query.filter(WikichunkEnrichment.url.in_(urls)).all():
        score = relevance_score(enrichment, text)
        if score>0:
            relevance_scores_per_url[enrichment.url] = score
    ranked = sorted(relevance_scores_per_url.items(), key=lambda x: x[1], reverse=True)
    urls = [ k for k,v in ranked ]
    if max_n_results>0:
        urls = urls[:max_n_results]
    return [ [ o for o in oers if o.url==url ][0] for url in urls ]


def autocomplete_terms_from_oer_collection(collection_title):
    if collection_title not in oer_collections:
        return []
    if collection_title not in autocomplete_cache:
        return []
    return autocomplete_cache[collection_title]


def initialise_caches_for_all_oer_collections():
    print('Initialising all collection caches.')
    for collection_title in oer_collections:
        initialise_cache(collection_title)


def initialise_cache(collection_title):
    print('Initialising cache for collection', collection_title)
    urls = oer_collections[collection_title]['video_urls']
    for url in urls:
        push_enrichment_task_if_needed(url, 10000)
    enrichments = [ w for w in WikichunkEnrichment.query.filter(WikichunkEnrichment.url.in_(urls)).all() ]
    autocomplete_cache[collection_title] = set([])
    for enrichment in enrichments:
        for title in enrichment.get_entity_titles():
            # NB it would be nice if we could guarantee that every
            # autocomplete suggestion definitely leads to >0 search results
            # but trying each one out takes a long time.
            # n = len(search_in_oer_collection(collection_title, title))
            # print(n, title)
            # if n > 0:
            autocomplete_cache[collection_title].add(title)


def concat_lists(list_of_lists):
    return [y for z in list_of_lists for y in z]


def relevance_score(enrichment, text):
    if enrichment.data['errors']:
        return 0
    if text=='':
        return 1
    p = re.compile(r'\b'+text+r'\b')
    n_text_matches = len(p.findall(enrichment.full_text().lower()))
    if n_text_matches==0:
        return 0
    n_chunk_matches = enrichment.all_entity_titles_as_lowercase_strings().count(text)
    if n_chunk_matches==0:
        return 0
    main_topics = concat_lists(enrichment.data['clusters'])
    main_topic_bonus = 10000 if text in [ t.lower() for t in main_topics ] else 0
    return (n_text_matches + 100*n_chunk_matches) / math.sqrt(len(enrichment.data['chunks'])) + main_topic_bonus


def predict_number_of_search_results_in_collection(text, collection_title):
    if collection_title not in oer_collections:
        return -1
    else:
        return len(search_in_oer_collections([collection_title], text, 0))


def export_oer_collections_oer_data_as_json_lines():
    print('export_oer_collections_oer_data_as_json_lines')
    with open('collections_oer_data.jsonl', 'w', encoding='utf-8') as f:
        for _,collection in oer_collections.items():
            for url in collection['video_urls']:
                oer = Oer.query.filter_by(url=url).first()
                if oer is not None:
                    json.dump(oer.data, f)
                    f.write('\n')
    print('done')
