from flask import Blueprint, render_template

plan = Blueprint('marketing', __name__)


@plan.route('/')
def index():
    return render_template('marketing/index.html')


@plan.route('/about')
def about():
    return render_template('marketing/about.html')


@plan.route('/manifesto')
def manifesto():
    return render_template('marketing/manifesto.html')


@plan.route('/how')
def how():
    return render_template('marketing/how.html')


@plan.route('/fees')
def fees():
    return render_template('marketing/fees.html')


@plan.route('/contact')
def contact():
    return render_template('marketing/contact.html')
