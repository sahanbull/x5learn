import pandas as pd

NODES_FILENAME = r"linkGraph-en-verts.txt"
EDGE_FILENAME = r"linkGraph-en-edges.txt"

PAGE_ID_FIELD = "PageId"
PAGE_TITLE_FIELD = "PageTitle"

FROM_PAGE_ID_FIELD = "FromPageId"
TO_PAGE_ID_FIELD = "ToPageId"


def load_wikipedia_graph_data(wiki_file_path):
    # load the nodes
    nodes = pd.read_csv(wiki_file_path + NODES_FILENAME, sep="\t")[[PAGE_ID_FIELD, PAGE_TITLE_FIELD]]
    node_dict = {}

    for idx, record in nodes.iterrows():
        node_dict[record[PAGE_ID_FIELD]] = record[PAGE_TITLE_FIELD]

    nodes = None

    # load the links
    edges = pd.read_csv(wiki_file_path + EDGE_FILENAME, sep="\t")[[FROM_PAGE_ID_FIELD, TO_PAGE_ID_FIELD]]

    print()

    # load the links
