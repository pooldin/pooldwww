import calendar
from flask import request, Blueprint, render_template, make_response
from flask.ext.login import current_user

from pooldlib.api import user

from pooldwww.app.negotiate import accepts

plan = Blueprint('profile', __name__)


@plan.route('/<string:username>', methods=['GET'], endpoint="view")
def view(username):
    usr = current_user._get_current_object()
    profile_usr = user.get_by_username(username)
    if not profile_usr:
        return "Unknown user: %s" % username, 404
    campaigns = list()
    for ca in sorted(profile_usr.campaigns, key=lambda x: x.campaign.name):
        c = ca.campaign
        end_time = calendar.timegm(c.end.timetuple()) * 1000
        # TODO :: This shoudl be comming from c.to_dict() <brian@poold.in>
        campaign = dict(id=c.id,
                        name=c.name,
                        end=end_time,
                        role=ca.role)
        campaigns.append(campaign)
    context = dict(title="%s's Poold.In profile." % username,
                   profile_user=profile_usr,
                   about=profile_usr.about if hasattr(profile_usr, 'about') else None,
                   campaigns=campaigns,
                   is_user=usr == profile_usr)
    return render_template('profile/view.html', **context)


@plan.route('/<string:username>/update', methods=['POST'], endpoint="update")
@accepts('application/json')
def update(username):
    usr = current_user._get_current_object()
    data = request.json
    if usr.username != username or username != data['username']:
        return "Silly little rabbit, this profile doesn't belong to you!", 503
    try:
        user.update(usr, **data)
    except Exception:
        # TODO :: Log that shit
        return "An unknown error occoured", 500

    return make_response('', 200)
