from flask import Blueprint

plan = Blueprint('marketing', __name__)


@plan.route('/')
def index():
    return 'Hello World!'


@plan.route('/about')
def about():
    return 'About'


@plan.route('/how')
def how():
    return 'How it works'


@plan.route('/fees')
def fees():
    return 'Fees'


@plan.route('/contact')
def contact():
    return 'Contact'
