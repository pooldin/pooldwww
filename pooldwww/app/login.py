from flask.ext.login import LoginManager, current_user
from pooldlib.api import user


def init_app(app):
    login = LoginManager()
    login.init_app(app)
    login.login_view = "auth.login"
    login.user_loader(load_user)
    app.context_processor(user_context)
    return app


def load_user(user_id):
    try:
        user_id = long(user_id)
    except (ValueError, TypeError):
        return
    return user.get_by_id(user_id)


def user_context():
    return dict(user=current_user)
