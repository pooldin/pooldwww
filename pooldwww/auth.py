from werkzeug.datastructures import ImmutableMultiDict
from flask import Blueprint, redirect, request, render_template
from wtforms import Form, BooleanField, TextField, PasswordField
from wtforms import ValidationError
from wtforms.validators import Email, EqualTo, Required, Length, Regexp
from pooldlib import exceptions as exc
from pooldlib.api import user

plan = Blueprint('auth', __name__)


class BaseForm(Form):

    @property
    def fields(self):
        fields = self._fields or dict()
        return fields.values()

    @property
    def error_list(self):
        errors = map(lambda f: f.errors, self.fields)
        return reduce(lambda l, r: l + r, errors)

    @property
    def error(self):
        errors = self.error_list

        if len(errors) > 0:
            return errors[0]

    def todict(self, *fields):
        return dict([(f.name, f.data)
                      for f in self.fields
                      if f.data is not None and
                         (not fields or f.name in fields)])


class SignupForm(BaseForm):
    email = TextField('Email', [
        Email(message='Invalid email address')
    ])
    username = TextField('Username', [
        Length(min=2, message='Username must have 2 or more characters')
    ])
    password = PasswordField('Password', [
        Required(message="Missing Password"),
        Length(min=7, message='Password must have at least 7 characters'),
        Regexp('.*\d+.*', message='Password must contain 1 or more numbers'),
    ])
    password_confirm = PasswordField('Confirm Password', [
        EqualTo('password', message='Passwords must match')
    ])

    @property
    def fields(self):
        return (self.email,
                self.username,
                self.password,
                self.password_confirm)

    def save(self):
        if not self.validate():
            raise ValidationError(self.error)
        try:
            return user.create(self.email.data, self.password.data)
        except exc.InvalidPasswordError:
            raise ValidationError('Invalid Password')
        except exc.UsernameUnavailableError:
            raise ValidationError('Username has already been taken')
        except exc.EmailUnavailableError:
            raise ValidationError('Email has already been taken')


class LoginForm(BaseForm):
    remember = BooleanField('Remember Me')
    login = TextField('Login', [
        Required(message='Email or Username is required')
    ])
    password = PasswordField('Password', [
        Required(message="Missing Password")
    ])

    def save(self):
        pass


@plan.route('/login', methods=['GET'])
def login(form=None):
    title = 'Welcome Back!'
    template = 'auth/login.html'

    if form:
        return render_template(template, title=title, form=form)

    form = dict()
    login = request.args.get('login')
    login = login or request.args.get('email')
    login = login or request.args.get('username')
    remember = request.args.get('remember') or ''

    if login:
        form['login'] = login

    if remember.lower() in ['true', '1']:
        form['remember'] = True

    form = ImmutableMultiDict(form.items())
    form = LoginForm(form)
    return render_template(template, title=title, form=form)


@plan.route('/login', methods=['POST'])
def login_post():
    form = LoginForm(request.form)

    try:
        form.save()
    except ValidationError, e:
        return e.message, 403

    return '', 201


@plan.route('/logout')
def logout():
    return redirect('auth.login')


@plan.route('/signup', methods=['GET'])
def signup(form=None):
    title = 'Create your Pooldin account.'
    template = 'auth/signup.html'

    if form:
        return render_template(template, form=form)

    form = dict()
    email = request.args.get('email')
    username = request.args.get('username')

    if email:
        form['email'] = email

    if username:
        form['username'] = username

    form = ImmutableMultiDict(form.items())
    form = SignupForm(form)
    return render_template(template, title=title, form=form)


@plan.route('/signup', methods=['POST'])
def signup_post():
    form = SignupForm(request.form)

    try:
        form.save()
    except ValidationError, e:
        return e.message, 403

    return '', 201
