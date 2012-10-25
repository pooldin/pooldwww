import re
import itsdangerous
from flask import current_app as app
from pooldlib.api import user
from pooldwww.exceptions import ValidationError


re_email = re.compile(r'^.+@[^.].*\.[a-z]{2,10}$', re.IGNORECASE)
re_has_number = re.compile(r'.*\d+.*')
re_username = re.compile(r'^\w+$')


def parse_boolean(value):
    if not isinstance(value, basestring):
        return bool(value)

    if value == '':
        return False

    return value.lower() in ['y', 'yes', 'true', '1']


def invalid(message, raise_error=True):
    if raise_error:
        raise ValidationError(message)
    return False


def validate_email(email, raise_error=True):
    if not email or not isinstance(email, basestring):
        return invalid('Email is required', raise_error=raise_error)

    if not re_email.match(email):
        return invalid('Email is not valid', raise_error=raise_error)

    return email


def validate_username(username, raise_error=True):
    if not username or not isinstance(username, basestring):
        return invalid('Username is required', raise_error=raise_error)

    if len(username) < 2:
        return invalid('Username must have 2 or more characters',
                       raise_error=raise_error)

    if not re_username.match(username):
        return invalid('Username can only contain numbers and letters',
                       raise_error=raise_error)

    return username


def validate_password(password, confirm, raise_error=True):
    if not password or not isinstance(password, basestring):
        return invalid('Password is required', raise_error=raise_error)

    if len(password) < 7:
        return invalid('Password must have at least 7 characters',
                       raise_error=raise_error)

    if not re_has_number.match(password):
        return invalid('Password must contain 1 or more number',
                       raise_error=raise_error)

    if password != confirm:
        return invalid('Password is not confirmed', raise_error=raise_error)

    return password


def validate_token(token, raise_error=True):
    if not token:
        return invalid('Invalid token', raise_error=raise_error)

    token = token.split('.')

    if len(token) < 2:
        return invalid('Invalid token', raise_error=raise_error)

    username = token[0]
    token = '.'.join(token[1:])
    usr = user.get_by_username(username)

    if not usr:
        return invalid('Invalid token', raise_error=raise_error)

    serializer = app.session_interface.get_serializer(app)

    try:
        token = serializer.loads(token, max_age=3600)
    except itsdangerous.BadData:
        if raise_error:
            raise
        return False

    if token != '%s%s' % (usr.id, usr.modified.isoformat()):
        return invalid('Invalid token', raise_error=raise_error)

    return usr
