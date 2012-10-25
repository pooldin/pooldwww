from flask import Blueprint, request
from flask.ext.login import current_user
from pooldlib.api import user

plan = Blueprint('verify', __name__)


@plan.route('/password', methods=['GET'])
def password():
    password = request.args.get('password')

    if not password:
        return 'Invalid password', 403

    usr = current_user._get_current_object()

    if not usr.is_authenticated():
        return 'Invalid password', 403

    if not user.verify_password(usr, password):
        return 'Invalid password', 403

    return '', 201


@plan.route('/email', methods=['GET'])
def email():
    email = request.args.get('email')

    if not email:
        return 'Invalid email', 403

    if not user.email_exists(email):
        return '', 200

    usr = current_user._get_current_object()

    if not usr.is_authenticated() or usr.email != email:
        return 'Email already taken', 403

    return '', 201


@plan.route('/username', methods=['GET'])
def username():
    username = request.args.get('username')

    if not username:
        return 'Invalid username', 403

    usr = current_user._get_current_object()

    if not user.username_exists(username):
        return '', 200

    if not usr.is_authenticated() or usr.username != username:
        return 'Username already taken', 403

    return '', 201
