#!/usr/bin/env bash

PYTHON_PATH="/home/ucl/anaconda3/envs/x5learn/bin/"

$PYTHON_PATH/pip install -e .

npm run setup
npm run build

cp -r uncompressed x5learn_server/static/dist
cp -r assets/img/* x5learn_server/static/dist/img
