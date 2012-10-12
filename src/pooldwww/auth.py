from flask import Blueprint

plan = Blueprint('auth', __name__)


@plan.route('/login')
def login():
    return 'Login'


@plan.route('/logout')
def logout():
    return 'Logout'
