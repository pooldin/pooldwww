from flask import Blueprint, render_template, redirect, request, url_for
from flask.ext.login import login_required, current_user
from pooldlib.api import user
from pooldlib.exceptions import InvalidPasswordError
from pooldwww.auth import validate_username, validate_email
from pooldwww.exceptions import ValidationError

plan = Blueprint('account', __name__)


@plan.route('/')
@login_required
def index():
    return redirect(url_for('account.details'))


@plan.route('/details', methods=['GET'])
@login_required
def details():
    return render_template('account/details.html')


@plan.route('/details', methods=['POST'])
@login_required
def profile_update():
    usr = current_user._get_current_object()
    fields = dict()
    name = request.form.get('name')
    email = request.form.get('email')
    username = request.form.get('username')

    try:
        if 'name' in request.form:
            fields['name'] = name or ''
        if 'username' in request.form:
            fields['username'] = validate_username(username)
        if 'email' in request.form:
            fields['email'] = validate_email(email)
    except ValidationError, e:
        return e.message, 403

    user.update(usr, **fields)
    return '', 201


@plan.route('/password', methods=['GET'])
@login_required
def password():
    return render_template('account/password.html')


@plan.route('/password', methods=['POST'])
@login_required
def password_change():
    old = request.form.get('old')
    new = request.form.get('new')
    confirm = request.form.get('confirm')

    usr = current_user._get_current_object()

    if not user.verify_password(usr, old):
        return 'Invalid old password', 403

    if new != confirm:
        return 'New password not confirmed', 403

    try:
        user.set_password(usr, new)
    except InvalidPasswordError:
        return 'Invalid new password', 403

    return '', 201
