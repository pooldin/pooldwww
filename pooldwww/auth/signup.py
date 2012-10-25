from flask import request, make_response, render_template, url_for
from flask.ext.login import login_user
from pooldlib import exceptions as exc
from pooldlib.api import user
from pooldwww.exceptions import ValidationError
from pooldwww.auth import plan
from pooldwww.auth.validate import (validate_email,
                                    validate_username,
                                    validate_password)


@plan.route('/signup', methods=['GET'], endpoint='signup')
def signup_get():
    context = dict(title='Create your Pooldin account.')
    email = request.args.get('email')
    username = request.args.get('username')

    if email:
        context['email'] = email

    if username:
        context['username'] = username

    return render_template('auth/signup.html', **context)


@plan.route('/signup', methods=['POST'])
def signup_post():
    try:
        signup(request.form)
    except ValidationError, e:
        return e.message, 403

    url = request.args.get('next')
    url = url or url_for('marketing.index')
    return make_response(('', 201, [('Location', url)]))


def signup(data, login=True, remember=False):
    data = data or dict()
    email = data.get('email')
    username = data.get('username')
    password = data.get('password')
    confirm = data.get('password_confirm')

    email = validate_email(email)
    username = validate_username(username)
    password = validate_password(password, confirm)

    try:
        usr = user.create(username, password, email=email)
    except exc.InvalidPasswordError:
        raise ValidationError('Invalid Password')
    except exc.UsernameUnavailableError:
        raise ValidationError('Username has already been taken')
    except exc.EmailUnavailableError:
        raise ValidationError('Email has already been taken')

    if login:
        login_user(usr, remember=remember)

    return usr
