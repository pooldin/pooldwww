import os

DEBUG = False
TESTING = False

DATABASE_URL = os.environ.get('DATABASE_URL')
DATABASE_URL = DATABASE_URL or 'postgresql://localhost/pooldin'
SQLALCHEMY_DATABASE_URI = DATABASE_URL
