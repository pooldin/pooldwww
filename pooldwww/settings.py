import os
import uuid

secret = os.environ.get('POOLDWWW_SECRET', uuid.uuid4().hex)
salt = os.environ.get('POOLDWWW_SESSION_SALT', uuid.uuid4().hex)


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
