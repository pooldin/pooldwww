import os

from flask import Flask
from flask.ext.assets import Environment
from webassets.loaders import YAMLLoader

from pooldlib.postgresql import db
from pooldwww import auth, legal, marketing, media


DIR = os.path.dirname(__file__)
DIR = os.path.abspath(DIR)

# Create app
app = Flask(__name__)

# Configure the app
os.environ.setdefault('POOLDWWW_SETTINGS', 'pooldwww.settings.dev')
app.config.from_object(os.environ.get('POOLDWWW_SETTINGS'))

if 'POOLDWWW_CONFIG' in os.environ:
    app.config.from_envvar('POOLDWWW_CONFIG')

# Configure and initialize assets
app.assets = Environment(app)
app.assets.auto_build = False
app.assets.directory = os.path.join(DIR, 'assets')
app.assets.manifest = 'file'
app.assets.url = '/static'

manifest = YAMLLoader(os.path.join(DIR, 'assets', 'manifest.yaml'))
manifest = manifest.load_bundles()
[app.assets.register(n, manifest[n]) for n in manifest]

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
