FROM node:lts-alpine AS react

COPY ./package.json package.json

RUN node --version

RUN yarn

COPY public public/

COPY app app/

RUN yarn build:cra


FROM python:3.12.2

RUN apt-get update -y && apt-get install -y exiftool

WORKDIR /home/ucl/x5learn
COPY ./setup.py setup.py
COPY x5learn_server x5learn_server/
COPY uncompressed x5learn_server/static/dist
COPY assets/img x5learn_server/static/dist/img
RUN pip install -e .
EXPOSE 8000

CMD ["python", "app.py"]
