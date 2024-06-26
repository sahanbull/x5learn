import os


TEMP_DIR = '/tmp/'


def temp_file_path(suffix):
    return TEMP_DIR+'x5learn_temp_'+str(os.getpid())+'.'+suffix



class EnrichmentError(ValueError):
    def __init__(self, message):
        self.message = message


def make_chunk(start, length, entities, text):
    return { 'start': start, 'length': length, 'entities': entities, 'text': text }
