import os

from flask import Flask
from flask.ext.assets import Environment
from webassets.loaders import YAMLLoader

from pooldlib.postgresql import db
from pooldwww import auth, legal, marketing, media


DIR = os.path.dirname(__file__)
DIR = os.path.abspath(DIR)

settings = os.environ.get('POOLDWWW_CONFIG')
settings = settings or 'pooldwww.settings.dev'

# Create app
app = Flask(__name__)

# Configure the app
app.config.from_object('pooldwww.settings.base')
app.config.from_object(settings)

# Configure and initialize assets
assets = os.path.join(DIR, 'assets')
manifest = os.path.join(assets, 'manifest.yaml')
manifest = YAMLLoader(manifest)
manifest = manifest.load_bundles()

app.assets = Environment(app)
app.assets.directory = assets
app.assets.url = '/static'
for name in manifest:
    app.assets.register(name, manifest[name])

# Initialize database
db.init_connection(app.config)

# Register all application blueprint
app.register_blueprint(media.plan)
app.register_blueprint(auth.plan)
app.register_blueprint(legal.plan)
app.register_blueprint(marketing.plan)


# Rollback any pending transaction, close any open cursors and close any
# open connections when the application is torn down.
@app.teardown_appcontext
def shutdown_session(response):
    db.session.remove()
