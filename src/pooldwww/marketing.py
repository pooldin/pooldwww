from flask import Blueprint, render_template
from pooldlib.postgresql import User

plan = Blueprint('marketing', __name__)


@plan.route('/')
def index():
    user = User.query.first()
    return render_template('marketing/index.html', user=user)


@plan.route('/about')
def about():
    return render_template('marketing/about.html')


@plan.route('/how')
def how():
    return render_template('marketing/how.html')


@plan.route('/fees')
def fees():
    return render_template('marketing/fees.html')


@plan.route('/contact')
def contact():
    return render_template('marketing/contact.html')
