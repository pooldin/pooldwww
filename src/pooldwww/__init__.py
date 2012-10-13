import os

from flask import Flask
from pooldlib.postgresql import db
from pooldwww import auth, legal, marketing, media

DIR = os.path.dirname(__file__)
DIR = os.path.abspath(DIR)

app = Flask(__name__)

settings = os.environ.get('POOLDIN_CONFIG')
settings = settings or 'pooldwww.config.DevelopmentConfig'
app.config.from_object(settings)
db.init_connection(app.config)


@app.teardown_appcontext
def shutdown_session(response):
    db.session.remove()


app.register_blueprint(media.plan)
app.register_blueprint(auth.plan)
app.register_blueprint(legal.plan)
app.register_blueprint(marketing.plan)
