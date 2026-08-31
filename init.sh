#!/usr/bin/env bash

source /venv/bin/activate
pip install -e .

npm install --legacy-peer-deps
npm run setup
npm run build:craco
npm run deploy:craco

mkdir -p x5learn_server/static/dist
cp -r uncompressed/* x5learn_server/static/dist
cp -r assets/img x5learn_server/static/dist/img

cd x5learn_server
flask run