import requests, math, json, os, sys, re

from wikichunkifiers.lib.util import temp_file_path, EnrichmentError, make_chunk
from wikichunkifiers.lib.wikify import get_entities, WIKIFIER_CHARACTER_LIMIT


def extract_chunks_from_youtube_video(url, data):
    print('\nin extract_chunks_from_youtube_video\n')
    transcript = data['transcript']
    duration = second_from_line(data['duration'])

    if isinstance(transcript, list):
        sections = sections_from_transcript_object(transcript, duration, 180)
    else:
        if len(transcript) < 500:
            raise EnrichmentError('transcript too short')

        sections = sections_from_transcript(transcript, duration, 180)

    chunks = []
    start = 0

    for index, section in enumerate(sections):
        print('Processing chunk', index+1, '/', len(sections))
        entities = get_entities(section.text)
        chunk = make_chunk(section.start_second / duration, section.length_seconds / duration, entities, section.text)
        # print(json.dumps(chunk, indent=4, sort_keys=True))
        chunks.append(chunk)

    # post-process the chunk lengths to make them stick precisely end to end
    for index, chunk in enumerate(chunks):
        end = 1 if index==len(chunks)-1 else chunks[index+1]['start']
        chunk['length'] = end - chunk['start']

    return chunks


class Section:
    def __init__(self, start_second, length_seconds, text):
        self.start_second = start_second
        self.length_seconds = length_seconds
        self.text = re.sub(r'[\n\r ]+', ' ', text).strip()

    @property
    def serialize(self):
        """Return object data in easily serializable format"""
        return {
            'start': self.start_second,
            'length': self.length_seconds,
            'text': self.text
        }


def sections_from_transcript(transcript, duration, approximate_target_chunk_size_in_seconds):
    transcript = re.sub(r'[A-Z][A-Z]+','', transcript) # remove allcaps words
    lines = transcript.split('\n')
    number_of_sections = max(1, int(duration / approximate_target_chunk_size_in_seconds))
    seconds_per_section = round(duration /number_of_sections - 0.01)
    print('Wikifying transcript. Approximate duration (seconds):', round(duration), '\tNumber of chunks:', number_of_sections,'\tSeconds per chunk:', seconds_per_section)
    start_second = 0
    sections = []
    text = ''
    for idx, line in enumerate(lines):
        if is_time(line):
            second = second_from_line(line)
            if second >= start_second + seconds_per_section:
                sections.append(Section(start_second, second-start_second, text))
                start_second = second
                text = ''
        else:
            text += ' '+line
    sections.append(Section(start_second, duration-start_second, text))
    return sections


# function to extract sections when transcript is from youtube scrapper
def sections_from_transcript_object(transcript, duration, approximate_target_chunk_size_in_seconds):

    number_of_sections = max(1, int(duration / approximate_target_chunk_size_in_seconds))
    seconds_per_section = round(duration /number_of_sections - 0.01)
    print('Wikifying transcript. Approximate duration (seconds):', round(duration), '\tNumber of chunks:', number_of_sections,'\tSeconds per chunk:', seconds_per_section)
    start_second = 0
    sections = []

    for idx, value in enumerate(transcript):
        second = int(round(value['start']))
        if second >= start_second + seconds_per_section:
            sections.append(Section(start_second, second-start_second, value['text']))
            start_second = second

    return sections

    
def second_from_line(line):
    try:
        seconds = int(line.split(':')[0]) * 60 + int(line.split(':')[1])
    except ValueError:
        # to support duration format extracted from youtube scrapper
        seconds = int(str(line.split('M')[0])[2:]) * 60 + int(line.split('M')[1].split('S')[0])

    return seconds


def is_time(line):
    return re.match(r'\d\d+:\d\d$', line)
