#!/usr/bin/env pwsh

.\.venv\Scripts\Activate.ps1
pip install -e .

npm install --legacy-peer-deps
npm run setup:mkdir
npm run build:css
npm run build:craco
npm run deploy:craco

New-Item -ItemType Directory -Force -Path x5learn_server\static\dist | Out-Null
Copy-Item -Recurse -Force uncompressed\* x5learn_server\static\dist
Copy-Item -Recurse -Force assets\img x5learn_server\static\dist\img

Set-Location x5learn_server
flask run
