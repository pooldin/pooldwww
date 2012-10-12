import os

DIR = os.path.dirname(__file__)
DIR = os.path.abspath(DIR)

from flask import Flask

app = Flask(__name__)


@app.route('/')
def index():
    return 'Hello World!'
