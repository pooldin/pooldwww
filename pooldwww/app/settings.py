import os
import uuid

secret = os.environ.get('POOLDWWW_SECRET', uuid.uuid4().hex)
salt = os.environ.get('POOLDWWW_SESSION_SALT', uuid.uuid4().hex)


def init_app(app):
    os.environ.setdefault('POOLDWWW_SETTINGS', 'pooldwww.app.settings.dev')
    app.config.from_object(os.environ['POOLDWWW_SETTINGS'])

    if 'POOLDWWW_CONFIG' in os.environ:
        app.config.from_envvar('POOLDWWW_CONFIG')


class base(object):
    DEBUG = False
    TESTING = False
    DATABASE_URL = os.environ.get('DATABASE_URL')
    DATABASE_URL = DATABASE_URL or 'postgresql://localhost/pooldin'
    SQLALCHEMY_DATABASE_URI = DATABASE_URL
    SECRET_KEY = secret
    SESSION_SALT = salt


class dev(base):
    DEBUG = True


class test(base):
    TESTING = True


class prod(base):
    pass
