from flask import Flask, jsonify, render_template, url_for, request
import urllib
import json
import http.client

app = Flask( __name__ )


@app.route("/")
def home():
    return render_template('home.html')

@app.route("/api/v1/search/", methods=['GET'])
def search():
    encoded_text = urllib.parse.quote(request.args['text'])
    conn = http.client.HTTPSConnection("platform.x5gon.org")
    conn.request('GET', '/api/v1/search/?url=https://platform.x5gon.org/materialUrl&text='+encoded_text)
    response = conn.getresponse().read().decode("utf-8")
    recommendations = json.loads(response)['recommendations'][:9]
    return jsonify(recommendations)

# @app.route("/<path:anything>")
# def product(anything):
#     return render_template('home.html')


if __name__ == ' __main__':
    app.run()
