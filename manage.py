import os
import sys

DIR = os.path.dirname(__file__)
DIR = os.path.abspath(DIR)
SRC = os.path.join(DIR, 'src')
sys.path.insert(0, SRC)

from pooldlib import cli
from pooldwww import app


class RootController(cli.RootController):
    class Meta:
        label = 'base'
        description = "Management tools for the Poold.in website."


class ServerController(cli.ServerController):
    flask_app = app


class App(cli.App):
    class Meta:
        label = 'pooldwww'
        base_controller = RootController
        handlers = (cli.ShellController,
                    ServerController)


if __name__ == '__main__':
    App.execute()
