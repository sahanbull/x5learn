# X5Learn

Experimental web frontend for X5GON project. www.x5gon.org

## Install

`npm install`

`npm run build`

## Build

To compile for production:

`npm run build`

To compile only the elm/javascript parts during development (including debug and without optimisation)

`npm run build:js-dev`

## Run locally

`FLASK_APP=server/app.py flask run --host=0.0.0.0`
