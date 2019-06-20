import sys
import os
import json
import jsondiff

from datetime import datetime

from sqlalchemy import DateTime, create_engine, Column, Integer, String, JSON
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

from requests import get
from bs4 import BeautifulSoup, SoupStrainer
import re
import time

from time import sleep

import random

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.firefox.options import Options


Base = declarative_base()

# engine = create_engine(os.environ['DATABASE_URL'])
engine = create_engine('postgresql://localhost/x5learn')
Session = sessionmaker(bind=engine)

session = Session()


###########################################################
# DB MODELS
###########################################################


class Oer(Base):
    __tablename__ = 'oer'
    id = Column(Integer(), primary_key=True)
    url = Column(String(255), unique=True, nullable=False)
    data = Column(JSON())

    def __init__(self, url, data):
        self.url = url
        self.data = data


###########################################################
# YOUTUBE SCRAPER
###########################################################

# Script adapted from https://github.com/bernorieder/youtube-transcript-scraper

waittime = 10                       # seconds browser waits before giving up
headless = True                     # select True if you want the browser window to be invisible (but not inaudible)

oers_csv_path = '/Users/stefan/x5/data/scenario_lab1/oers.csv'


def backup_and_save(df, path):
    copy(path, '/'.join(path.split('/')[:-1])+'/auto_backup/'+str(int(time.time()))+'_'+path.split('/')[-1])
    df.to_csv(path, sep='\t', encoding='utf-8', index=False)

def get_duration_from_youtube(url):
    txt = get(url).text
    if '"status":"UNPLAYABLE"' in txt:
        raise ValueError('unplayable')
    duration = int(txt.split('lengthSeconds\\":\\"')[1].split('\\')[0])
    print('duration = ', duration)    
    return duration


# def get_main_concepts_from_wikifier_org__and_update_mapping_between_ids_and_titles(text):
#     payload = {'userKey': 'yeydkrkxbnrfxcgayvanalxesqqwja',
#                'text': text,
#                 'lang': 'auto',
#                 'support': 'false',
#                 'ranges': 'false',
#                 'includeCosines': 'true',
#                 'nTopDfValuesToIgnore': 50,
#                 'nWordsToIgnoreFromList': 50,
#               }
#     r = requests.post("http://www.wikifier.org/annotate-article", data=payload)
#     j = json.loads(r.text)
#     annotations = sorted(j['annotations'], key=lambda k: k['pageRank'], reverse=True)[:5]
#     main_concepts = []
#     # store mappings in json file
#     titles_filepath = '/Users/stefan/x5/data/scenario_sigchi/wiki_id_title_mapping.json'
#     with open(titles_filepath, 'r') as f:
#         titles = json.load(f)
#     for a in annotations:
#         if 'wikiDataItemId' in a:
#             concept_id = a['wikiDataItemId']
#             title = a['title']
#             titles[concept_id] = title
#             main_concepts.append(concept_id)
#             print(concept_id, title)
#     print('___________________________________')
#     with open(titles_filepath, 'w') as f:
#         json.dump(titles, f)
#     return main_concepts


def second_from_line(line):
    return int(line.split(':')[0])* 60 + int(line.split(':')[1])

def is_time(line):
    return re.match(r'\d\d+:\d\d$', line)




def scrape_youtube_page(videoid):
        print('Scraping Youtube video', videoid)
                # Create a new instance of the Firefox driver
        if headless:
            options = Options()
            options.headless = True
            driver = webdriver.Firefox(options=options)
        else:
            driver = webdriver.Firefox()

        sleep(2)

        # navigate to video
        url = "https://www.youtube.com/watch?v="+videoid
        driver.get(url)

        sleep(3)

        try:
            element = WebDriverWait(driver, waittime).until(EC.presence_of_element_located((By.CSS_SELECTOR, "yt-icon-button.dropdown-trigger > button:nth-child(1)")))
        except:
                msg = 'could not find options button'
                driver.quit()
                return msg

        try:
                sleep(random.uniform(4,8))
                element.click()
        except:
                msg = 'could not click dropdown trigger'
                driver.quit()
                return msg

        try:
            sleep(random.uniform(2,4))
            #print('about to find transcript button')
            element = driver.find_element_by_css_selector('.ytd-popup-container > paper-listbox').find_element_by_xpath('ytd-menu-service-item-renderer[1]')
            sleep(random.uniform(0.5,1.5))
            element.click()
            #print('clicked transcript button')
            sleep(random.uniform(1,2))
            element = WebDriverWait(driver, waittime).until(EC.presence_of_element_located((By.CSS_SELECTOR, "ytd-transcript-body-renderer.style-scope")))
            transcript = element.text
        except:
            msg = 'No transcript available'
            driver.quit()
            return msg

        try:
                #print('about to click show-more button')
                sleep(random.uniform(1,2))
                element = WebDriverWait(driver, waittime).until(EC.presence_of_element_located((By.CSS_SELECTOR, ".more-button.style-scope.ytd-video-secondary-info-renderer")))
                element.click()
                #print('clicked show-more button')
        except:
                msg = 'could not click show-more button'
                driver.quit()
                return msg

        try:
            sleep(random.uniform(1,2))
            element = WebDriverWait(driver, waittime).until(EC.presence_of_element_located((By.CSS_SELECTOR, "#description.style-scope.ytd-video-secondary-info-renderer")))
            description = element.text
        except:
                msg = 'could not find description text'
                driver.quit()
                return msg

        try:
            sleep(random.uniform(1,2))
            element = WebDriverWait(driver, waittime).until(EC.presence_of_element_located((By.CSS_SELECTOR, "h1.style-scope.ytd-video-primary-info-renderer")))
            title = element.text
        except:
                msg = 'could not find title text'
                driver.quit()
                return msg

        try:
            sleep(random.uniform(1,2))
            element = WebDriverWait(driver, waittime).until(EC.presence_of_element_located((By.CSS_SELECTOR, ".date.style-scope.ytd-video-secondary-info-renderer")))
            date = element.text
        except:
                msg = 'could not find date text'
                driver.quit()
                return msg

        try:
            sleep(random.uniform(1,2))
            element = WebDriverWait(driver, waittime).until(EC.presence_of_element_located((By.CSS_SELECTOR, "#owner-name.style-scope.ytd-video-owner-renderer ")))
            provider = element.text
        except:
                msg = 'could not find date text'
                driver.quit()
                return msg

        driver.quit()


        return {'transcript': transcript, 'title': title, 'description': description, 'date': date, 'provider': provider}


###########################################################
# MAIN SCRIPT
###########################################################


def ingest_oer_from_url(url):
    # import pdb; pdb.set_trace()
    print('\n______________________________________________________________')
    print(url)
    oer = session.query(Oer).filter_by(url=url).first()
    if oer is not None:
        print('Exists already -> skipping.')
        return True
    videoid = url.split('watch?v=')[1].split('&')[0]
    print(videoid)
    info = scrape_youtube_page(videoid)
    if isinstance(info, str):
        print('Error:', info)
        return False
    else:
        info['images'] = ['https://i.ytimg.com/vi/'+videoid+'/hqdefault.jpg']
        info['duration'] = get_duration_from_youtube(url)
        oer = Oer(url, info)
        session.add(oer)
        session.commit()
        return True


if __name__ == '__main__':
    urls = ... (insert urls)
    for url in urls:
        success = ingest_oer_from_url(url)
        while not success:
            print('Retrying...')
            success = ingest_oer_from_url(url)
    print('Done.')
