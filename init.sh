#!/usr/bin/env bash

PYTHON_PATH="/home/ucl/anaconda3/envs/x5learn/bin/"

$PYTHON_PATH/pip install -e .

yarn setup
#npm run build

yarn build:craco
yarn deploy:craco


cp -r uncompressed/* x5learn_server/static/dist
cp -r assets/img x5learn_server/static/dist/img