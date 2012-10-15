from flask import Blueprint, render_template

plan = Blueprint('legal', __name__)


@plan.route('/privacy')
def privacy():
    return render_template('legal/privacy.html')


@plan.route('/terms')
def terms():
    return render_template('legal/terms.html')
