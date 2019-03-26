from server.wiki_api._wiki_db import load_wikipedia_graph_data

TEST_DATA_FILEPATH = "C:/Users/in4maniac/Documents/Data/x5gon/wikipedia/"

def test_load_wikipedia_graph_data():
    load_wikipedia_graph_data(TEST_DATA_FILEPATH)

    assert False