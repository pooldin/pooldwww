from flask import make_response, redirect, render_template, request, url_for
from flask.ext.login import login_user, logout_user
from pooldlib.api import user
from pooldwww.auth import plan
from pooldwww.auth.validate import parse_boolean
from pooldwww.exceptions import ValidationError
from pooldwww.app.negotiate import accepts


@plan.route('/login', methods=['GET'], endpoint='login')
def login_get(form=None):
    title = 'Welcome Back!'
    template = 'auth/login.html'

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
@accepts('application/json')
def login_post():
    try:
        login(request.json)
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


def login(data):
    data = data or dict()

    usr = user.get_by_username(data.get('login'))

    if not usr:
        usr = user.get_by_email(data.get('login'))

    if not usr:
        raise ValidationError('Invalid login or password')

    if not user.verify_password(usr, data.get('password')):
        raise ValidationError('Invalid login or password')

    remember = parse_boolean(data.get('remember'))
    login_user(usr, remember=remember)
    return usr
