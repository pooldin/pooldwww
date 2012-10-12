import os
import sys
from cement.core import controller

DIR = os.path.dirname(__file__)
DIR = os.path.abspath(DIR)
SRC = os.path.join(DIR, 'src')
sys.path.insert(0, SRC)

from pooldlib import cli
from pooldlib.flask import test
from pooldwww import app


class RootController(cli.RootController):
    class Meta:
        label = 'base'
        description = "Management tools for the Poold.in website."


class ServerController(cli.ServerController):
    flask_app = app


class TestController(cli.Controller):

    class Meta:
        label = 'test'
        description = "Run the pooldwww test suite"

    @controller.expose(hide=True, help='Run the pooldwww test suite')
    def default(self):
        test.run('pooldwww.test')


class App(cli.App):
    class Meta:
        label = 'pooldwww'
        base_controller = RootController
        handlers = (cli.ShellController,
                    ServerController,
                    TestController)


if __name__ == '__main__':
    App.execute()
