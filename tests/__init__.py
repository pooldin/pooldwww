from flask import testsuite
from pooldlib.flask import test
from pooldwww import app


class FlaskTestCase(test.RequestCaseMixin,
                    test.SessionCaseMixin,
                    test.ContextCaseMixin,
                    testsuite.FlaskTestCase):

    def create_app(self):
        return app

    def __call__(self, result=None):
        self.setup_context()
        super(FlaskTestCase, self).__call__(result)
        self.teardown_context()
