from flask import Blueprint, render_template, redirect, url_for
from flask.ext.login import login_required

plan = Blueprint('settings', __name__)


@plan.route('/')
@login_required
def index():
    return redirect(url_for('settings.profile'))


@plan.route('/profile', methods=['GET'])
@login_required
def profile():
    return render_template('settings/profile.html')


@plan.route('/password', methods=['GET'])
@login_required
def password():
    return render_template('settings/password.html')
