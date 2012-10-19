from werkzeug.datastructures import CallbackDict
from flask.sessions import SessionInterface, SessionMixin
from itsdangerous import URLSafeTimedSerializer, BadSignature


class ItsdangerousSession(CallbackDict, SessionMixin):

    def __init__(self, initial=None):
        def on_update(self):
            self.modified = True
        CallbackDict.__init__(self, initial, on_update)
        self.modified = False


class ItsdangerousSessionInterface(SessionInterface):
    session_class = ItsdangerousSession

    def __init__(self, *args, **kw):
        salt = kw.pop('salt') or getattr(self, 'salt', None)

        super(ItsdangerousSessionInterface, self).__init__(*args, **kw)

        if not salt:
            raise ValueError('Missing salt value')

        self.salt = salt

    def get_serializer(self, app):
        if app.secret_key:
            return URLSafeTimedSerializer(app.secret_key, salt=self.salt)

    def open_session(self, app, request):
        serializer = self.get_serializer(app)

        if serializer is None:
            return

        value = request.cookies.get(app.session_cookie_name)

        if not value:
            return self.session_class()

        max_age = app.permanent_session_lifetime.total_seconds()

        try:
            data = serializer.loads(value, max_age=max_age)
            return self.session_class(data)
        except BadSignature:
            return self.session_class()

    def save_session(self, app, session, response):
        domain = self.get_cookie_domain(app)

        if not session:
            if session.modified:
                response.delete_cookie(app.session_cookie_name,
                                       domain=domain)
            return

        if app.permanent_session_lifetime:
            session.permanent = True

        expires = self.get_expiration_time(app, session)
        path = self.get_cookie_path(app)

        data = dict(session)
        data = self.get_serializer(app).dumps(data)

        response.set_cookie(app.session_cookie_name,
                            data,
                            expires=expires,
                            httponly=True,
                            domain=domain,
                            path=path)
