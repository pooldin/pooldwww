import re
from flask import Blueprint, redirect, request, render_template, url_for
from flask import make_response
from flask.ext.login import login_user, logout_user
from pooldlib import exceptions as exc
from pooldlib.api import user
from pooldwww.exceptions import ValidationError

plan = Blueprint('auth', __name__)

re_email = re.compile(r'^.+@[^.].*\.[a-z]{2,10}$', re.IGNORECASE)
re_has_number = re.compile(r'.*\d+.*')
re_username = re.compile(r'^\w+$')


def parse_boolean(value):
    if not isinstance(value, basestring):
        return bool(value)

    if value == '':
        return False

    return value.lower() not in ['n', 'no', 'false', '0']


def validate_email(email):
    if not email or not isinstance(email, basestring):
        raise ValidationError('Email is required')

    if not re_email.match(email):
        raise ValidationError('Email is not valid')

    return email


def validate_username(username):
    if not username or not isinstance(username, basestring):
        raise ValidationError('Username is required')

    if len(username) < 2:
        raise ValidationError('Username must have 2 or more characters')

    if not re_username.match(username):
        raise ValidationError('Username can only contain numbers and letters')

    return username


def validate_password(password, confirm):
    if not password or not isinstance(password, basestring):
        raise ValidationError('Password is required')

    if len(password) < 7:
        raise ValidationError('Password must have at least 7 characters')

    if not re_has_number.match(password):
        raise ValidationError('Password must contain 1 or more number')

    if password != confirm:
        raise ValidationError('Password is not confirmed')

    return password


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


def login(data):
    data = data or dict()

    usr = user.get(data.get('login'))

    if not usr:
        raise ValidationError('Invalid login or password')

    if not user.verify_password(usr, data.get('password')):
        raise ValidationError('Invalid login or password')

    remember = parse_boolean(data.get('remember'))
    login_user(usr, remember=remember)
    return usr


@plan.route('/login', methods=['GET'], endpoint='login')
def login_get(form=None):
    title = 'Welcome Back!'
    template = 'login.html'

    if form:
        return render_template(template, title=title, **form)

    form = dict()
    login = request.args.get('login')
    login = login or request.args.get('email')
    login = login or request.args.get('username')
    remember = request.args.get('remember') or ''

    if login:
        form['login'] = login

    if remember.lower() in ['true', '1']:
        form['remember'] = True

    return render_template(template, title=title, **form)


@plan.route('/login', methods=['POST'])
def login_post():
    try:
        login(request.form)
    except ValidationError, e:
        return e.message, 403

    url = request.args.get('next')
    url = url or url_for('marketing.index')
    return make_response(('', 201, [('Location', url)]))


@plan.route('/logout')
def logout():
    logout_user()
    url = request.args.get('next')
    url = url or url_for('marketing.index')
    return redirect(url)


@plan.route('/signup', methods=['GET'], endpoint='signup')
def signup_get(form=None):
    title = 'Create your Pooldin account.'
    template = 'signup.html'

    if form:
        return render_template(template, **form)

    form = dict()
    email = request.args.get('email')
    username = request.args.get('username')

    if email:
        form['email'] = email

    if username:
        form['username'] = username

    return render_template(template, title=title, **form)


@plan.route('/signup', methods=['POST'])
def signup_post():
    try:
        signup(request.form)
    except ValidationError, e:
        return e.message, 403

    url = request.args.get('next')
    url = url or url_for('marketing.index')
    return make_response(('', 201, [('Location', url)]))
