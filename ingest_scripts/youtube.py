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


CALTECH = ['https://www.youtube.com/watch?v=mbyG85GZ0PI&list=PLD63A284B7615313A&index=1',
     'https://www.youtube.com/watch?v=MEG35RDD7RA&list=PLD63A284B7615313A&index=2',
     'https://www.youtube.com/watch?v=FIbVs5GbBlQ&list=PLD63A284B7615313A&index=3',
     'https://www.youtube.com/watch?v=L_0efNkdGMc&list=PLD63A284B7615313A&index=4',
     'https://www.youtube.com/watch?v=SEYAnnLazMU&list=PLD63A284B7615313A&index=5',
     'https://www.youtube.com/watch?v=6FWRijsmLtE&list=PLD63A284B7615313A&index=6',
     'https://www.youtube.com/watch?v=Dc0sr0kdBVI&list=PLD63A284B7615313A&index=7',
     'https://www.youtube.com/watch?v=zrEyxfl2-a8&list=PLD63A284B7615313A&index=8',
     'https://www.youtube.com/watch?v=qSTHZvN8hzs&list=PLD63A284B7615313A&index=9',
     'https://www.youtube.com/watch?v=Ih5Mr93E-2c&list=PLD63A284B7615313A&index=10',
     'https://www.youtube.com/watch?v=EQWr3GGCdzw&list=PLD63A284B7615313A&index=11',
     'https://www.youtube.com/watch?v=I-VfYXzC5ro&list=PLD63A284B7615313A&index=12',
     'https://www.youtube.com/watch?v=o7zzaKd0Lkk&list=PLD63A284B7615313A&index=13',
     'https://www.youtube.com/watch?v=eHsErlPJWUU&list=PLD63A284B7615313A&index=14',
     'https://www.youtube.com/watch?v=XUj5JbQihlU&list=PLD63A284B7615313A&index=15',
     'https://www.youtube.com/watch?v=O8CfrnOPtLc&list=PLD63A284B7615313A&index=16',
     'https://www.youtube.com/watch?v=EZBUDG12Nr0&list=PLD63A284B7615313A&index=17',
     'https://www.youtube.com/watch?v=ihLwJPHkMRY&list=PLD63A284B7615313A&index=18']

STANFORD = ['https://www.youtube.com/watch?v=6QRpDLj8huE&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=1',
     'https://www.youtube.com/watch?v=W46UTQ_JDPk&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=2',
     'https://www.youtube.com/watch?v=WXNUbLC8A4I&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=3',
     'https://www.youtube.com/watch?v=UVCFaaEBnTE&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=4',
     'https://www.youtube.com/watch?v=lZit4Uzlswc&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=5',
     'https://www.youtube.com/watch?v=4u81xU7BIOc&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=6',
     'https://www.youtube.com/watch?v=QjOILAQ0EFg&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=7',
     'https://www.youtube.com/watch?v=SGEroEKFbnY&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=8',
     'https://www.youtube.com/watch?v=UVjj2fHu9YU&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=9',
     'https://www.youtube.com/watch?v=zNhCF97exlA&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=10',
     'https://www.youtube.com/watch?v=Tppi2Fof1DE&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=11',
     'https://www.youtube.com/watch?v=uV5TnFc7eaE&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=12',
     'https://www.youtube.com/watch?v=0D4LnsJr85Y&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=13',
     'https://www.youtube.com/watch?v=pAwjiGkafbM&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=14',
     'https://www.youtube.com/watch?v=UqqPm-Q4aMo&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=15',
     'https://www.youtube.com/watch?v=GIcuSNAAa4g&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=16',
     'https://www.youtube.com/watch?v=ed4whd9B-xw&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=17',
     'https://www.youtube.com/watch?v=_GvMC0ZYvK8&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=18',
     'https://www.youtube.com/watch?v=oByDE-RJkZA&list=PLoR5VjrKytrCv-Vxnhp5UyS1UjZsXP0Kj&index=19']


# https://www.youtube.com/results?search_query=machine+learning+introduction
FIRST_PAGE_OF_SEARCH_RESULTS_FOR_MACHINE_LEARNING_INTRODUCTION = ['https://www.youtube.com/watch?v=ukzFI9rgwfU',
     'https://www.youtube.com/watch?v=IpGxLWOIZy4',
     'https://www.youtube.com/watch?v=h0e2HAPTGF4',
     'https://www.youtube.com/watch?v=ujTCoH21GlA',
     'https://www.youtube.com/watch?v=hjh1ikznScg',
     'https://www.youtube.com/watch?v=Gv9_4yMHFhI',
     'https://www.youtube.com/watch?v=GvQwE2OhL8I',
     'https://www.youtube.com/watch?v=JgvyzIkgxF0',
     'https://www.youtube.com/watch?v=4vGiHC35j9s',
     'https://www.youtube.com/watch?v=nKW8Ndu7Mjw',
     'https://www.youtube.com/watch?v=cKxRvEZd3Mw',
     'https://www.youtube.com/watch?v=JN6H4rQvwgY',
     'https://www.youtube.com/watch?v=63NTeLmDANo',
     'https://www.youtube.com/watch?v=8onB7rPG4Pk',
     'https://www.youtube.com/watch?v=SN2BZswEWUA',
     'https://www.youtube.com/watch?v=Q59X518JZHE',
     'https://www.youtube.com/watch?v=aircAruvnKk',
     'https://www.youtube.com/watch?v=5hNK7-N23eU',
     'https://www.youtube.com/watch?v=-DEL6SVRPw0',
     'https://www.youtube.com/watch?v=BR9h47Jtqyw',
     'https://www.youtube.com/watch?v=O5xeyoRL95U',
     'https://www.youtube.com/watch?v=J1_A-rdNBNQ']


def human_readable_time_from_seconds(seconds):
    minutes = int(seconds / 60)
    seconds = int(seconds - minutes * 60)
    return str(minutes) + ':' + str(seconds).rjust(2, '0')


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
    data = scrape_youtube_page(videoid)
    if isinstance(data, str):
        print('Error:', data)
        return False
    else:
        data['images'] = ['https://i.ytimg.com/vi/'+videoid+'/hqdefault.jpg']
        data['duration'] = human_readable_time_from_seconds(get_duration_from_youtube(url))
        data['mediatype'] = 'video'
        data['url'] = url
        data['mediatype'] = 'video'
        if data['provider']=='caltech':
            data['provider'] = 'Caltech'
        if data['provider']=='Machine Learning and AI':
            data['provider'] = 'Stanford'
        if len(data['provider']) > 20:
            data['provider'] = data['provider'] + '…'
        oer = Oer(url, data)
        session.add(oer)
        session.commit()
        return True


if __name__ == '__main__':
    urls = CALTECH + STANFORD + FIRST_PAGE_OF_SEARCH_RESULTS_FOR_MACHINE_LEARNING_INTRODUCTION

    for url in urls:
        success = ingest_oer_from_url(url)
        while not success:
            print('Retrying...')
            success = ingest_oer_from_url(url)
    print('Done.')
