import os
import uuid

database = os.environ.get('DATABASE_URL')
database = os.environ.get('POOLDWWW_DATABASE_URL', database)
database = database or 'postgresql://localhost/pooldin'
secret = os.environ.get('POOLDWWW_SECRET', uuid.uuid4().hex)
salt = os.environ.get('POOLDWWW_SESSION_SALT', uuid.uuid4().hex)
whitelist = os.environ.get('POOLDWWW_WHITELIST', '')
whitelist = whitelist.split('|')
blacklist = os.environ.get('POOLDWWW_BLACKLIST', '')
blacklist = blacklist.split('|')


def init_app(app):
    os.environ.setdefault('POOLDWWW_SETTINGS', 'pooldwww.app.settings.dev')
    app.config.from_object(os.environ['POOLDWWW_SETTINGS'])

    if 'POOLDWWW_CONFIG' in os.environ:
        app.config.from_envvar('POOLDWWW_CONFIG')


class base(object):
    DEBUG = False
    TESTING = False
    SQLALCHEMY_DATABASE_URI = database
    SECRET_KEY = secret
    SESSION_SALT = salt
    WHITELIST = whitelist
    BLACKLIST = blacklist


class dev(base):
    DEBUG = True


class test(base):
    TESTING = True


class prod(base):
    pass
