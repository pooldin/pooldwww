from functools import wraps
import time
from datetime import datetime
import calendar
from decimal import Decimal
import json

from flask import request, Blueprint, render_template, make_response, url_for, redirect
from flask import current_app as app
from flask.ext.login import login_required, current_user, login_fresh

from pooldlib.api import campaign, fee, user, currency
from pooldlib.exceptions import (PreviousStripeAssociationError,
                                 ExternalAPIUsageError,
                                 ExternalAPIError,
                                 ExternalAPIUnavailableError,
                                 StripeCustomerAccountError,
                                 StripeUserAccountError,
                                 CampaignConfigurationError,
                                 DuplicateCampaignUserAssociationError)

from pooldwww.convert import string_to_bool
from pooldwww.exceptions import ValidationError
from pooldwww.app.negotiate import accepts

plan = Blueprint('pool', __name__)

QUANTIZE_DOLLARS = Decimal(10) ** -2


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
    usr = current_user._get_current_object()
    if c is None:
        return '', 404

    organizer = campaign.organizer(c)
    organizer_is_viewing = usr == organizer

    if not usr.is_anonymous():
        campaign_association = [p for p in usr.campaigns if p.campaign == c]
        campaign_association = campaign_association[0] if campaign_association else None
        if campaign_association is not None:
            campaign_association.pledge = campaign_association.pledge.quantize(QUANTIZE_DOLLARS) if campaign_association.pledge else 0
    else:
        campaign_association = None
    is_participant = campaign_association is not None

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
               'amount': str(participant.pledge) if participant.pledge else 0,
               'invitee': False}
        if not organizer_is_viewing:
            base_name = new['email'].split('@')[0]
            new['email'] = '%s@...' % base_name
        community.append(new)
    for invitee in c.invitees:
        if invitee.accepted is not None:
            continue

        gravatar_url = app.gravatar(invitee.user.email, size=60) if invitee.user else None
        gravatar_url = app.gravatar(invitee.email, size=60) if gravatar_url is None else gravatar_url
        invited_date_ms = calendar.timegm(invitee.created.timetuple()) * 1000
        new = {'name': invitee.user.display_name if invitee.user else None,
               'username': invitee.user.username if invitee.user else None,
               'email': invitee.email,
               'link': '/profile/%s' % participant.user.username if invitee.user else None,
               'gravatar': gravatar_url,
               'isOrganizer': False,
               'joinedDate': invited_date_ms,
               'invitee': True,
               'amount': 0}
        if not organizer_is_viewing:
            base_name = new['email'].split('@')[0]
            new['email'] = '%s@...' % base_name
        community.append(new)

    timestamp_ms = calendar.timegm(c.end.timetuple()) * 1000
    is_active = time.time() * 1000 <= timestamp_ms

    # This is a temporary shim while we transition campaign descriptions to
    # JSON data
    try:
        c.description = json.loads(c.description)
    except ValueError:
        c.description = {'text': c.description}
    context = dict(title="Pool: %s" % c.name,
                   campaign=c,
                   organizer=organizer,
                   participants=json.dumps(community),
                   timestamp=timestamp_ms,
                   invitees=c.participants,
                   is_organizer=organizer_is_viewing,
                   is_participant=is_participant,
                   is_active=is_active,
                   campaign_association=campaign_association)
    return render_template('pool/view.html', **context)


@plan.route('/<int:id>/fees', methods=['GET'], endpoint="fees")
def fees_get(id=None):
    amount = request.args.get('amount')
    if amount is None:
        return "'amount' qs argument required", 400
    amount = Decimal(str(amount))
    # for now we assume 2 fees: Stripe and Poold
    fees = fee.get(None, fee_names=['stripe-transaction', 'poold-transaction'])
    ledger = fee.calculate(fees, amount)
    ledger = sanitize_json(ledger)
    return make_response((json.dumps(ledger), 200, [('Content-Type', 'application/json')]))


def sanitize_json(json):
    if isinstance(json, dict):
        for (k, v) in json.items():
            json[k] = str(v) if isinstance(v, Decimal) else v
            if isinstance(v, (dict, list, tuple)):
                json[k] = sanitize_json(v)
    if isinstance(json, (list, tuple)):
        for (i, item) in enumerate(json):
            json[i] = sanitize_json(item)
    return json


@plan.route('/<int:id>/join', methods=['GET'], endpoint="join")
def join_get(id=None):
    c = campaign.get(id)
    if c is None:
        return "Unknown campaign.", 404
    timestamp_ms = calendar.timegm(c.end.timetuple()) * 1000
    _campaign = dict(id=c.id,
                     amount=c.amount,
                     end=timestamp_ms,
                     name=c.name,
                     suggestedContribution=c.suggested_contribution,
                     contributionRequired=string_to_bool(c.suggested_contribution_required))
    context = dict(campaign=_campaign,
                   stripe_publishable_key=app.config.get('STRIPE_PUBLIC_KEY'),
                   loggedIn=not current_user.is_anonymous(),
                   success_response="""{"name": "%s", "date": 0, "charge": {"initial": "0", "final": "0"}, "fees": []}""" % c.name)
    context['require_login'] = not login_fresh()
    return render_template('pool/join.html', **context)


@plan.route('/<int:id>/join', methods=['POST'])
@accepts('application/json')
@login_required
def join_post(id=None):
    data = request.json
    c = campaign.get(id)
    if c is None:
        return "Unknown campaign.", 404
    usr = current_user._get_current_object()
    token = data['stripeToken']
    full_name = data['fullName']
    stripe_private_key = app.config.get('STRIPE_SECRET_KEY')
    try:
        user.associate_stripe_token(usr, token, stripe_private_key, True)
    except (PreviousStripeAssociationError,
            ExternalAPIUsageError):
        return make_response(('We boned it, please try again later.', 500))
    except (ExternalAPIError,
            ExternalAPIUnavailableError):
        return make_response((json.dumps({'error': 'Request failed due to an external dependency.'}), 424))

    charge = c.disburse_funds_when == 'immediately'
    amount = Decimal(data.get('amount'))
    curr = data.get('currency')
    curr = currency.get(curr)
    fees = fee.get(None, fee_names=['stripe-transaction', 'poold-transaction'])

    if charge:
        success = charge_user(usr, c, amount, curr, fees, full_name=full_name)
        if not success:
            return make_response(('We boned it, please try again later.', 500))
    try:
        campaign.associate_user(c, usr, 'participant', 'participating', pledge=amount)
    except DuplicateCampaignUserAssociationError:
        campaign.update_user_association(c, usr, role=None, pledge=amount)

    ledger = fee.calculate(fees, amount)
    ledger['date'] = datetime.utcnow().strftime('%m/%d/%Y')
    send_receipt_email(c, usr, ledger)

    ledger = sanitize_json(ledger)
    ledger['date'] = int(time.time()) * 1000

    return make_response((json.dumps(ledger), 201, [('Content-Type', 'application/json')]))


def charge_user(usr, cpgn, amount, curr, fees, full_name=None):
    try:
        user.payment_to_campaign(usr, cpgn, amount, curr, fees, full_name=full_name)
    except (StripeCustomerAccountError,
            StripeUserAccountError,
            CampaignConfigurationError):
        return False
    return True


@plan.route('/create', methods=['GET'], endpoint="create")
@login_required
def create_get():
    usr = current_user._get_current_object()
    if usr.is_anonymous():
        url = url_for('login')
        return redirect(url)

    whitelisted = usr.email.endswith('poold.in') or usr.email in app.config.get('USER_WHITELIST')
    if not whitelisted:
        return render_template('pool/sorry.html')

    stripe_connected = hasattr(usr, 'stripe_user_id') and hasattr(usr, 'stripe_user_token')
    if not stripe_connected:
        url = '%s?next=%s' % (url_for('account.stripe'), url_for('pool.create'))
        return redirect(url)

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

    milestones = sorted(milestones, key=lambda x: x['date'])
    if disburse_funds_when != 'immediately':
        milestones.insert(0, default_milestone)
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
    ccs = [organizer.email]
    bccs = [app.config.get('BCC_CAMPAIGN_ADDRESS')]
    for invite in invites:
        # This should be a shortened URL
        subs['campaign_url'] = '%s?invite=%s' % (campaign_url, invite.id)
        email_text = text.render(**subs)
        app.emailer.send_text(subject, email_text, [invite.email], ccs=ccs, bccs=bccs)


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
    ccs = [organizer.email]
    bccs = [app.config.get('BCC_CAMPAIGN_ADDRESS')]
    app.emailer.send_text(subject, email_text, emails, ccs=ccs, bccs=bccs, disclose_recipients=False)


def send_receipt_email(contrib_campaign, usr, ledger):
    organizer = campaign.organizer(contrib_campaign)
    poold_url = request.url_root.rstrip('/')
    campaign_url = '/'.join([
        poold_url,
        url_for('pool.view', id=contrib_campaign.id).lstrip('/')
    ])

    payment_fee = poold_fee = None
    for fee in ledger['fees']:
        if fee['name'] == 'stripe-transaction':
            payment_fee = fee['fee']
        if fee['name'] == 'poold-transaction':
            poold_fee = fee['fee']

    subs = dict(organizer_name=organizer.display_name,
                organizer_email=organizer.email,
                campaign_name=contrib_campaign.name,
                poold_url=poold_url,
                campaign_url=campaign_url,
                charge=ledger['charge']['final'],
                contribution=ledger['charge']['initial'],
                payment_fee=payment_fee,
                poold_fee=poold_fee)
    subject = "Receipt for you contribution to '%(campaign_name)s'!"
    subject %= subs
    text = app.jinja_env.get_template('email/receipt.txt')

    email_text = text.render(**subs)
    bccs = [app.config.get('BCC_RECEIPT_ADDRESS'), organizer.email]
    app.emailer.send_text(subject, email_text, [usr.email], bccs=bccs, disclose_recipients=False)
