import itsdangerous
from flask import current_app as app
from pooldlib.api import user
from pooldwww.auth.validate import invalid


class Token(object):

    @classmethod
    def create(self, usr, serializer=None):
        if not serializer:
            serializer = app.session_interface.get_serializer(app)

        value = '%s%s' % (usr.id, usr.modified.isoformat())
        token = serializer.dumps(value)
        return self('%s.%s' % (usr.username, token))

    def __init__(self, value):
        self.value = value

    @property
    def token(self):
        return self._token

    @property
    def username(self):
        return self._username

    def value_getter(self):
        return self._value

    def value_setter(self, value):
        username = None
        token = None
        if isinstance(value, basestring):
            parts = value.split('.')
            if len(parts) > 1:
                username = parts[0]
                token = '.'.join(parts[1:])

        self._username = username
        self._token = token
        self._value = value

        if hasattr(self, '_user'):
            del self._user

    value = property(value_getter, value_setter)

    @property
    def user(self):
        if not hasattr(self, '_user'):
            usr = self.load_user(raise_error=False)
            if usr:
                self._user = usr
            else:
                self._user = None
        return self._user

    def load_user(self, raise_error=True):
        username = getattr(self, 'username', None)
        token = getattr(self, 'token', None)

        if not username or not token:
            return invalid('Invalid token', raise_error=raise_error)

        usr = user.get_by_username(username)
        seed = '%s%s' % (usr.id, usr.modified.isoformat())

        if not usr:
            return invalid('Invalid token', raise_error=raise_error)

        serializer = app.session_interface.get_serializer(app)

        try:
            token = serializer.loads(token, max_age=3600)
        except itsdangerous.BadData:
            if raise_error:
                raise
            return False

        if token != seed:
            return invalid('Invalid token', raise_error=raise_error)

        return usr
