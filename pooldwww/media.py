import os
from flask import Blueprint, send_from_directory
from flask import current_app as app

plan = Blueprint('media', __name__)


def send_static_file(path, mimetype=None):
    static = os.path.join(app.root_path, 'static')

    if not mimetype:
        return send_from_directory(static, path)

    return send_from_directory(static, path, mimetype=None)


@plan.route('/favicon.ico')
def favicon():
    return send_static_file('favicon.ico', mimetype='image/vnd.microsoft.icon')


@plan.route('/crossdomain.xml')
def crossdomain():
    return send_static_file('crossdomain.xml', mimetype='text/xml')


@plan.route('/robots.txt')
def robots():
    return send_static_file('robots.txt', mimetype='plain/text')
