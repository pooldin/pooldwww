import os

from webassets.loaders import YAMLLoader
from flask import Flask
from flask.ext.assets import Environment
from flask.ext.gravatar import Gravatar
from flask.ext.seasurf import SeaSurf
from pooldlib.postgresql import db

from pooldwww import DIR, account, media, auth, legal, marketing, pool, verify, profile
from pooldwww.app import email, login, session, settings, restrict


def create_app(*args, **kw):
    app = Flask(*args, **kw)
    settings.init_app(app)
    session.init_app(app)
    init_assets(app)
    init_database(app)
    login.init_app(app)
    init_gravatar(app)
    init_seasurf(app)
    init_blueprints(app)
    email.init_app(app)
    restrict.init_app(app)
    return app


def init_assets(app):
    app.assets = Environment(app)
    app.assets.auto_build = False
    app.assets.directory = os.path.join(DIR, 'assets')
    app.assets.manifest = 'file'
    app.assets.url = '/static'

    manifest = YAMLLoader(os.path.join(DIR, 'assets', 'manifest.yaml'))
    manifest = manifest.load_bundles()
    [app.assets.register(n, manifest[n]) for n in manifest]


def init_database(app):
    db.init_connection(app.config)
    app.teardown_appcontext(lambda r: db.session.remove())


def init_seasurf(app):
    app.csrf = SeaSurf(app)


def init_gravatar(app):
    app.gravatar = Gravatar(app,
                            size=350,  # Default to header profile image size
                            default='mm',  # Options available at gravatar.com
                            force_default=False,
                            force_lower=False)


def init_blueprints(app):
    app.register_blueprint(media.plan)
    app.register_blueprint(auth.plan)
    app.register_blueprint(verify.plan, url_prefix='/verify')
    app.register_blueprint(account.plan, url_prefix='/account')
    app.register_blueprint(legal.plan)
    app.register_blueprint(marketing.plan)
    app.register_blueprint(pool.plan, url_prefix='/pool')
    app.register_blueprint(profile.plan, url_prefix='/profile')
