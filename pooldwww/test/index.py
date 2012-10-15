from pooldlib.flask.test import TestSuite
from pooldwww.test import FlaskTestCase


def suite():
    return TestSuite.create([
        IndexTestCase,
    ])


class IndexTestCase(FlaskTestCase):

    def test_hello(self):
        resp = self.get('/')
        assert resp.status_code == 200
        assert resp.data == 'Hello World!'
