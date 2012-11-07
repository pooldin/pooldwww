import os
import uuid

database = os.environ.get('DATABASE_URL')
database = os.environ.get('POOLDWWW_DATABASE_URL', database)
database = database or 'postgresql://localhost/pooldin'
whitelist = os.environ.get('POOLDWWW_WHITELIST', '')
whitelist = filter(lambda ip: ip, whitelist.split('|'))
blacklist = os.environ.get('POOLDWWW_BLACKLIST', '')
blacklist = filter(lambda ip: ip, blacklist.split('|'))


def init_app(app):
    os.environ.setdefault('POOLDWWW_SETTINGS', 'pooldwww.app.settings.dev')
    app.config.from_object(os.environ['POOLDWWW_SETTINGS'])

    if 'POOLDWWW_CONFIG' in os.environ:
        app.config.from_envvar('POOLDWWW_CONFIG')


class base(object):
    DEBUG = False
    TESTING = False
    SQLALCHEMY_DATABASE_URI = database
    SECRET_KEY = os.environ.get('POOLDWWW_SECRET', uuid.uuid4().hex)
    SESSION_SALT = os.environ.get('POOLDWWW_SESSION_SALT', uuid.uuid4().hex)
    EMAIL_HOST = os.environ.get('POOLDWWW_EMAIL_HOST')
    EMAIL_PORT = os.environ.get('POOLDWWW_EMAIL_PORT')
    EMAIL_USERNAME = os.environ.get('POOLDWWW_EMAIL_USERNAME')
    EMAIL_PASSWORD = os.environ.get('POOLDWWW_EMAIL_PASSWORD')
    EMAIL_SENDER = os.environ.get('POOLDWWW_EMAIL_SENDER')
    WHITELIST = whitelist
    BLACKLIST = blacklist
    SESSION_COOKIE_NAME = 'poold_session'
    CSRF_COOKIE_NAME = 'poold_csrf'
    CSRF_DISABLE = False
    GOOGLE_ANALYTICS_ID = os.environ.get('POOLDWWW_GOOGLE_ANALYTICS_ID')
    STRIPE_PUBLIC_KEY = os.environ.get('STRIPE_PUBLIC_KEY')
    STRIPE_APP_CID = os.environ.get('STRIPE_APP_CID')
    STRIPE_SECRET_KEY = os.environ.get('STRIPE_SECRET_KEY')


class dev(base):
    DEBUG = True


class test(base):
    TESTING = True


class prod(base):
    pass
