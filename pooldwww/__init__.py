import os

DIR = os.path.dirname(__file__)
DIR = os.path.abspath(DIR)

from pooldwww.app import create_app
app = create_app(__name__)
