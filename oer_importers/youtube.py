import sys
import os
import json
import argparse

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


# For relative imports to work in Python 3.6
sys.path.append(os.path.dirname(os.path.realpath(__file__)))

from x5learn_server._config import DB_ENGINE_URI, PASSWORD_SECRET
from x5learn_server.db.database import Base, get_or_create_db
db_session = get_or_create_db(DB_ENGINE_URI)
from x5learn_server.models import Oer



###########################################################
# YOUTUBE SCRAPER
###########################################################

# Script adapted from https://github.com/bernorieder/youtube-transcript-scraper

waittime = 10                       # seconds browser waits before giving up
headless = True                     # select True if you want the browser window to be invisible (but not inaudible)


def get_duration_from_youtube(url):
    txt = get(url).text
    if '"status":"UNPLAYABLE"' in txt:
        raise ValueError('unplayable')
    txt = txt.replace('[Music]', '')
    duration = int(txt.split('lengthSeconds\\":\\"')[1].split('\\')[0])
    print('duration = ', duration)
    return duration


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
            transcript = element.text.strip()
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


def human_readable_time_from_seconds(seconds):
    minutes = int(seconds / 60)
    seconds = int(seconds - minutes * 60)
    return str(minutes) + ':' + str(seconds).rjust(2, '0')


def ingest_oer_from_url(url):
    videoid = url.split('watch?v=')[1].split('&')[0]
    data = scrape_youtube_page(videoid)
    if isinstance(data, str):
        print('Error:', data)
        errors[url] = data
        return False
    else:
        data['images'] = ['https://i.ytimg.com/vi/'+videoid+'/hqdefault.jpg']
        data['duration'] = human_readable_time_from_seconds(get_duration_from_youtube(url))
        data['mediatype'] = 'video'
        data['url'] = url
        data['mediatype'] = 'video'

        # clean up names for the initial lab study
        if data['provider']=='caltech':
            data['provider'] = 'Caltech'
        if data['provider']=='Machine Learning and AI':
            data['provider'] = 'Stanford'

        oer = Oer(url, data)
        db_session.add(oer)
        db_session.commit()
        return True


errors = {}


if __name__ == '__main__':
    parser=argparse.ArgumentParser(
        description='''X5Learn ingestion script for youtube videos. ''',
        epilog="""NB existing videos won't be overwritten.""")
    parser.add_argument('urls', type=str, help='Text file containing a newline-separated list of video urls')
    args=parser.parse_args()
    urls = open(args.urls).readlines()
    urls = [ u.strip() for u in urls ]

    skipped = []
    succeeded_at_first_try = []
    succeeded_at_second_try = []
    failed = []

    for url in urls:
        print('\n______________________________________________________________')
        print(url)
        oer = db_session.query(Oer).filter_by(url=url).first()
        if oer is not None:
            print('Exists already -> skipping.')
            skipped.append(url)
        elif ingest_oer_from_url(url):
            succeeded_at_first_try.append(url)
        elif ingest_oer_from_url(url):
            succeeded_at_second_try.append(url)
        else:
            print('Giving up.')
            failed.append(url)

    print(len(urls), 'URLs processed.\n')

    print(len(skipped), 'videos skipped.')
    print(len(succeeded_at_first_try), 'videos succeeded at first try.')
    print(len(succeeded_at_second_try), 'videos succeeded at second try.')
    print(len(failed), 'videos failed.')

    print()

    if len(errors)==0:
        print('All videos ingested successfully.')
    else:
        print('Failed URLs:')
        for url, error in errors.items():
            print(url, error)
