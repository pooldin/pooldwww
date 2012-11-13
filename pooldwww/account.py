from flask import Blueprint, render_template, redirect, request, url_for, current_app
from flask.ext.login import login_required, current_user

from pooldlib.api import user
from pooldlib.exceptions import (InvalidPasswordError,
                                 PreviousStripeAssociationError,
                                 ExternalAPIUsageError,
                                 ExternalAPIError,
                                 ExternalAPIUnavailableError)
from pooldwww.auth.validate import validate_username, validate_email
from pooldwww.exceptions import ValidationError
from pooldwww.app.negotiate import accepts

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
@accepts('application/json')
@login_required
def profile_update():
    usr = current_user._get_current_object()
    fields = dict()
    name = request.json.get('name')
    email = request.json.get('email')
    username = request.json.get('username')

    try:
        if 'name' in request.json:
            fields['name'] = name or ''
        if 'username' in request.json:
            fields['username'] = validate_username(username)
        if 'email' in request.json:
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
@accepts('application/json')
@login_required
def password_change():
    old = request.json.get('old')
    new = request.json.get('new')
    confirm = request.json.get('confirm')

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


@plan.route('/stripe/test', methods=['GET'])
@login_required
def test_connect():
    return render_template('account/stripe_test.html')


@plan.route('/stripe/connect', methods=['GET'])
@login_required
def stripe_connect():
    # TODO :: Error responses need to be end user friendly
    usr = current_user._get_current_object()
    if not 'state' in request.args:
        return 'Unauthorized', 401
    csrf_token = request.args['state']
    if not current_app.csrf._get_token() == csrf_token:
        return 'Unauthorized', 401

    if 'code' in request.args:
        code = request.args['code']
        stripe_secret_key = current_app.config.get('STRIPE_SECRET_KEY')
        try:
            user.associate_stripe_authorization_code(usr,
                                                     code,
                                                     stripe_secret_key)
        except PreviousStripeAssociationError:
            return 'Previous Stripe Connect account association found.', 409
        except ExternalAPIUsageError:
            return 'An internal error prevented your request from being completed.', 500
        except (ExternalAPIError, ExternalAPIUnavailableError):
            return 'An error occoured with an external service preventing your request from being completed.', 500
        return redirect(url_for('account.stripe_connect_success'))
    elif 'error' in request.args:
        # Redirect user to account for the connect denial in our analytics
        return redirect(url_for('account.stripe_connect_denied'))


@plan.route('/stripe/connect/complete', methods=['GET'])
@login_required
def stripe_connect_success():
    return render_template('account/stripe_connect_success.html')


@plan.route('/stripe/connect/denied', methods=['GET'])
@login_required
def stripe_connect_denied():
    return render_template('account/stripe_connect_denied.html')
