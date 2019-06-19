# X5Learn

Experimental web frontend for X5GON project. www.x5gon.org

## Install

Install node and npm. On Linux: `sudo apt install nodejs-legacy npm`

`npm install`

`sh init.sh`

## Build

To compile for production:

`npm run build`

To compile only the elm/javascript parts during development (including debug and without optimisation)

`npm run build:js-dev`

## Run locally

Start the flask app:

`FLASK_APP=server/app.py flask run --host=0.0.0.0`

Start an enrichment worker:

`cd enrichments`

`nohup python enrichment_worker.py&`

Repeat the above command to run multiple workers in parallel.

## Extend

To install new Elm packages:

`./node_modules/elm/bin/elm install <name of package>`
