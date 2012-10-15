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


class AssetController(cli.Controller):

    class Meta:
        label = 'assets'
        description = "Build, watch or clean static assets"
        arguments = [
            (['-b', '--bundle'], {
                'action': 'append',
                'help': 'Build bundle asset',
                'default': [],
            }),
            (['-f', '--force'], {
                'action': 'store_true',
                'help': 'Force build even if it exists',
            })
        ]

    @controller.expose(hide=True, help='Build, watch or clean static assets')
    def default(self):
        self.app.args.print_help()

    @controller.expose(help='Build static assets')
    def build(self):
        args = ['build'] + self.pargs.bundle
        self.run(*args)

    @controller.expose(help='Rebuild static assets')
    def rebuild(self):
        args = ['build', '--no-cache'] + self.pargs.bundle
        self.run(*args)

    @controller.expose(help='Clean static assets')
    def clean(self):
        self.run('clean')

    def run(self, *args):
        from webassets import script
        script.main(args, env=app.assets)


class App(cli.App):
    class Meta:
        label = 'pooldwww'
        base_controller = RootController
        handlers = (cli.ShellController,
                    ServerController,
                    TestController,
                    AssetController)


if __name__ == '__main__':
    App.execute()
