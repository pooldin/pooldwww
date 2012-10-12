import os

from flask import Flask
from pooldwww import auth, legal, marketing, media

DIR = os.path.dirname(__file__)
DIR = os.path.abspath(DIR)

app = Flask(__name__)
app.register_blueprint(media.plan)
app.register_blueprint(auth.plan)
app.register_blueprint(legal.plan)
app.register_blueprint(marketing.plan)
