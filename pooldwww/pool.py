from functools import wraps
from datetime import datetime
import calendar
from decimal import Decimal
import json

from flask import request, Blueprint, render_template, make_response, url_for
from flask import current_app as app
from flask.ext.login import login_required, current_user

from pooldlib.api import campaign

from pooldwww.exceptions import ValidationError
from pooldwww.app.negotiate import accepts

plan = Blueprint('pool', __name__)


def wrap_campaign_organizer_only(fn, message):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        campaign_id = kwargs['id']
        c = campaign.get(campaign_id)
        organizer = campaign.organizer(c)
        if current_user._get_current_object() != organizer:
            return message, 401
        return fn(*args, **kwargs)
    return wrapper


def organizer_only(message):
    def decorated(fn):
        return wrap_campaign_organizer_only(fn, message)
    return decorated


@plan.route('/<int:id>', methods=['GET'], endpoint="view")
def view(id):
    c = campaign.get(id)
    organizer = campaign.organizer(c)
    organizer_is_viewing = current_user._get_current_object() == organizer
    community = list()
    for participant in c.participants:
        gravatar_url = app.gravatar(participant.user.email or 'anonymous@poold.in', size=60)
        joined_date_ms = calendar.timegm(participant.created.timetuple()) * 1000
        new = {'name': participant.user.display_name,
               'username': participant.user.username,
               'email': participant.user.email,
               'link': '/profile/%s' % participant.user.username,
               'gravatar': gravatar_url,
               'isOrganizer': participant.user == organizer,
               'joinedDate': joined_date_ms,
               'amount': participant.pledge or 100,
               'invitee': False}
        if not organizer_is_viewing:
            base_name = new['email'].split('@')[0]
            new['email'] = '%s@CENSORED' % base_name
        community.append(new)
    for invitee in c.invitees:
        if invitee.accepted is not None:
            continue

        gravatar_url = app.gravatar(invitee.user.email, size=60) if invitee.user else\
                       app.gravatar(invitee.email, size=60)
        invited_date_ms = calendar.timegm(invitee.created.timetuple()) * 1000
        new = {'name': invitee.user.display_name if invitee.user else None,
               'username': invitee.user.username if invitee.user else None,
               'email': invitee.email,
               'link': '/profile/%s' % participant.user.username if invitee.user else None,
               'gravatar': gravatar_url,
               'isOrganizer': False,
               'joinedDate': invited_date_ms,
               'invitee': True,
               'amoutn': 0}
        if not organizer_is_viewing:
            base_name = new['email'].split('@')[0]
            new['email'] = '%s@CENSORED' % base_name
        community.append(new)

    timestamp_ms = calendar.timegm(c.end.timetuple()) * 1000
    # This is a temporary shim while we transition campaign descriptions to
    # JSON data
    try:
        c.description = json.loads(c.description)
    except ValueError:
        c.description = {'text': c.description}
    context = dict(title="Pool: %s" % c.name,
                   campaign=c,
                   organizer=organizer,
                   total_poold=Decimal('350.26'),
                   participants=json.dumps(community),
                   timestamp=timestamp_ms,
                   invitees=c.participants,
                   is_organizer=organizer_is_viewing)
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


@plan.route('/<int:id>/update', methods=['POST'], endpoint="update")
@accepts('application/json')
@organizer_only("Only organizer's can update campaigns!")
@login_required
def update_post(id=None):
    data = request.json
    if 'timestamp' not in data or not isinstance(data['timestamp'], int):
        return "Campaign description updates must include an integer timestamp", 400
    if 'text' not in data:
        return "Campaign updates don't work if you don't update the campaign!", 400

    description = update(id, data)
    return json.dumps(description), 200


@plan.route('/<int:id>/send/invite', methods=['POST'], endpoint="send_invite")
@accepts('application/json')
@organizer_only("Only organizer's can invie people to campaigns!")
@login_required
def send_invite_post(id=None):
    data = request.json

    if 'to' not in data:
        return "Invites don't work too well without the 'who'!", 400
    if 'message' not in data:
        return "You must supply a message for the invite emails!", 400

    data['to'] = data['to'].split(',')
    invite(id, data)
    return '', 201


@plan.route('/<int:id>/send/update', methods=['POST'], endpoint="send_update")
@accepts('application/json')
@organizer_only("Only organizer's can send out campaign updates!")
@login_required
def send_update_post(id=None):
    c = campaign.get(id)
    data = request.json

    if 'to' not in data:
        return "Updates don't work too well without the 'who'!", 400
    if 'message' not in data:
        return "You must supply a message for the update email!", 400

    emails = data['to'].split(',')
    message = data['message']

    send_update_email(c, emails, message)
    return '', 201


def create(data, usr):
    data = data or dict()
    name = data.get('name')
    description = data.get('description')
    if isinstance(description, basestring):
        description = json.dumps(dict(text=description))

    milestones = data.get('milestones', [])

    timestamp = data.get('date')
    timestamp /= 1000
    date = datetime.utcfromtimestamp(int(timestamp))

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
    default_milestone = {'name': 'pi-default-milestone',
                         'description': 'pi-default-milestone',
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


def update(campaign_id, data):
    c = campaign.get(campaign_id)
    description = c.description
    try:
        description = json.loads(description)
    except ValueError:
        description = dict(text=description)

    if 'updates' not in description:
        description['updates'] = list()

    description['updates'].append(data)

    campaign.update(c, description=json.dumps(description))

    return description


def invite(campaign_id, data):
    c = campaign.get(campaign_id)
    emails = data['to']
    message = data['message']
    invites = campaign.add_invites(c, emails)
    if emails:
        send_invite_email(c, invites, message)


def send_invite_email(invite_to_campaign, invites, message):
    organizer = campaign.organizer(invite_to_campaign)
    poold_url = request.url_root.rstrip('/')
    campaign_url = '/'.join([
        poold_url,
        url_for('pool.view', id=invite_to_campaign.id).lstrip('/')
    ])

    subs = dict(organizer_name=organizer.display_name,
                organizer_email=organizer.email,
                message=message,
                campaign_name=invite_to_campaign.name,
                poold_url=poold_url)
    subject = "%(organizer_name)s (%(organizer_email)s) has invited to participate in their poold.in campaign!"
    subject %= subs
    text = app.jinja_env.get_template('email/invite.txt')
    for invite in invites:
        # This should be a shortened URL
        subs['campaign_url'] = '%s?invite=%s' % (campaign_url, invite.id)
        email_text = text.render(**subs)
        app.emailer.send_text(subject, email_text, [invite.email])


def send_update_email(update_campaign, emails, message):
    organizer = campaign.organizer(update_campaign)
    poold_url = request.url_root.rstrip('/')
    campaign_url = '/'.join([
        poold_url,
        url_for('pool.view', id=update_campaign.id).lstrip('/')
    ])

    subs = dict(organizer_name=organizer.display_name,
                organizer_email=organizer.email,
                message=message,
                campaign_name=update_campaign.name,
                poold_url=poold_url,
                campaign_url=campaign_url)
    subject = "We have an update for you regarding '%(campaign_name)s' from %(organizer_name)s (%(organizer_email)s)!"
    subject %= subs
    text = app.jinja_env.get_template('email/update.txt')

    email_text = text.render(**subs)
    app.emailer.send_text(subject, email_text, emails, disclose_recipients=False)
