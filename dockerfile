FROM node:lts-alpine AS react

COPY ./package.json package.json

RUN node --version

RUN yarn

COPY public public/

COPY app app/

RUN yarn build:cra


FROM rackspacedot/python37

RUN apt-get update -y && apt-get install -y exiftool

WORKDIR /home/ucl/x5learn

COPY ./requirements.txt requirements.txt

RUN pip install -r requirements.txt



COPY test-integration test-integration/
COPY ./setup.py setup.py
COPY x5learn_server x5learn_server/
#RUN pip install -e .


COPY ./init-docker.sh init-docker.sh
#cp -r uncompressed/* x5learn_server/static/dist
#cp -r assets/img x5learn_server/static/dist/img

#RUN ./init-docker.sh

