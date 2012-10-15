from pooldlib.flask.test import TestSuite
from . import FlaskTestCase


def suite():
    return TestSuite.create([
        IndexTestCase,
    ])


class IndexTestCase(FlaskTestCase):

    def test_hello(self):
        resp = self.get('/')
        assert resp.status_code == 200
