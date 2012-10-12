from flask import Blueprint

plan = Blueprint('legal', __name__)


@plan.route('/privacy')
def privacy():
    return 'Privacy Policy'


@plan.route('/terms')
def terms():
    return 'Terms and conditions'
