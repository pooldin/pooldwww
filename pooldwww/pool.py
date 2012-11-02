from flask import Blueprint, render_template
from flask.ext.login import login_required

plan = Blueprint('pool', __name__)


@plan.route('/create', methods=['GET'])
@login_required
def create():
    return render_template('pool/create.html')
