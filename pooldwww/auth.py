from flask import Blueprint, redirect, render_template

plan = Blueprint('auth', __name__)


@plan.route('/login')
def login():
    return render_template('auth/login.html')


@plan.route('/logout')
def logout():
    return redirect('auth.login')


@plan.route('/signup')
def signup():
    return render_template('auth/signup.html')
