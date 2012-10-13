import os

DATABASE_URL = os.environ.get('DATABASE_URL')
DATABASE_URL = DATABASE_URL or 'postgresql://localhost/pooldin'


class Config(object):
    DEBUG = False
    TESTING = False
    SQLALCHEMY_DATABASE_URI = DATABASE_URL


class DevelopmentConfig(Config):
    DEBUG = True


class ProductionConfig(Config):
    pass
