from flask import Flask, render_template, url_for

app = Flask( __name__ )


@app.route("/")
def home():
    return render_template('home.html')

@app.route("/<path:anything>")
def product(anything):
    return render_template('home.html')


if __name__ == ' __main__':
    #app.debug = True
    app.run()
