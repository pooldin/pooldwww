import calendar
from datetime import datetime
from decimal import Decimal
import json

from flask import request, Blueprint, render_template, make_response, url_for, current_app
from flask.ext.login import login_required, current_user

from pooldlib.api import campaign

from pooldwww.exceptions import ValidationError
from pooldwww.app.negotiate import accepts

plan = Blueprint('pool', __name__)


@plan.route('/<int:id>', methods=['GET'], endpoint="view")
def view(id):
    c = campaign.get(id)
    organizer = campaign.organizer(c)
    participants = list()
    for participant in c.participants:
        gravatar_url = current_app.gravatar(participant.user.email or 'anonymous@poold.in', size=60)
        participants.append({'name': participant.user.display_name,
                             'gravatar': gravatar_url,
                             'role': participant.role,
                             'status': 'active member'})

    context = dict(title="Pool: %s" % c.name,
                   campaign=c,
                   organizer=organizer,
                   total_poold=Decimal('350.26'),
                   participants=json.dumps(participants),
                   timestamp=calendar.timegm(c.end.timetuple()),
                   invitees=c.participants,
                   is_organizer=(current_user._get_current_object() == organizer))
    return render_template('pool/view.html', **context)


@plan.route('/create', methods=['GET'], endpoint="create")
@login_required
def create_get():
    context = dict(title="Create Pool")
    return render_template('pool/create.html', **context)


@plan.route('/create', methods=['POST'])
@accepts('application/json')
@login_required
def create_post():
    usr = current_user._get_current_object()
    try:
        c = create(request.json, usr)
    except ValidationError, e:
        return e.message, 403
    url = url_for('pool.view', id=c.id)
    return make_response(('', 201, [('Location', url)]))


def create(data, usr):
    data = data or dict()
    name = data.get('name')
    description = data.get('description')
    milestones = data.get('milestones', [])

    date = data.get('date')
    date = datetime.utcfromtimestamp(int(date))

    amount = data.get('amount')
    suggested_contribution = data.get('contribution')
    suggested_contribution_required = data.get('required_contribution')
    collect_funds_when = data.get('fund_collection')
    disburse_funds_when = data.get('disburse_funds')
    meta = dict(amount=amount,
                collect_funds_when=collect_funds_when,
                disburse_funds_when=disburse_funds_when)
    if suggested_contribution:
        meta['suggested_contribution'] = suggested_contribution
        meta['suggested_contribution_required'] = suggested_contribution_required

    c = campaign.create(usr,
                        name,
                        description,
                        end=date,
                        **meta)
    default_milestone = {'name': 'default-milestone',
                         'description': 'default-milestone',
                         'date': date,
                         'type': 'project'}
    milestones = milestones or [default_milestone]
    milestones = sorted(milestones, key=lambda x: x['date'])
    g = None
    for milestone in milestones:
        g = campaign.add_goal(c,
                              milestone['name'],
                              milestone['description'],
                              milestone['type'],
                              predecessor=g,
                              end=milestone['date'])

    return c
