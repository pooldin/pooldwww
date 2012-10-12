from flask import Blueprint, render_template

plan = Blueprint('auth', __name__)


@plan.route('/login')
def login():
    return render_template('auth/login.html')


@plan.route('/logout')
def logout():
    return render_template('auth/logout.html')
