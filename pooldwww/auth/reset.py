from flask import flash, make_response, render_template, request, url_for
from flask import current_app as app
from flask.ext.login import login_user
from pooldlib.api import user
from pooldwww.auth import plan
from pooldwww.auth.token import Token
from pooldwww.auth.validate import validate_password


@plan.route('/reset', methods=['GET'], endpoint='reset')
def reset_get():
    template = 'auth/reset.html'
    context = dict(title='Reset your password')
    email = request.args.get('email')
    t = request.args.get('t')
    token = Token(request.args.get('t'))

    if email:
        context['email'] = email

    if token.user:
        template = 'auth/change.html'
        context['token'] = token.value
    elif t:
        flash('Invalid or Expired Token')

    return render_template(template, **context)


@plan.route('/reset', methods=['POST'])
def reset_post():
    email = request.form.get('email')
    password = request.form.get('password')
    confirm = request.form.get('password_confirm')
    token = request.args.get('t')
    token = request.form.get('t', token)
    token = Token(token)

    if email:
        usr = user.get_by_email(email)
        if usr:
            reset_email(usr)
        return '', 201

    if not validate_password(password, confirm, raise_error=False):
        return 'Invalid password', 403

    if not token.value:
        return 'Invalid token', 403

    if not token.user:
        return 'Invalid token', 403

    user.set_password(token.user, password)
    login_user(token.user, remember=False)

    url = request.args.get('next')
    url = url or url_for('marketing.index')
    return make_response(('', 201, [('Location', url)]))


def reset_email(usr):
    token = Token.create(usr)

    if not token.user:
        return

    url = '/'.join([
        request.url_root.rstrip('/'),
        url_for('auth.reset').lstrip('/')
    ])

    url = '%s?t=%s' % (url, token.value)

    text = app.jinja_env.get_template('email/reset.txt')
    text = text.render(url=url, email=token.user.email)
    return app.emailer.send_text(text, [usr.email])
