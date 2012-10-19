"""
pooldwww
========

This is the poold.in website. It currently depends on the pooldb and the
pooldlib projects for database management and common code.

More to come as the news develops.
"""

import os
import sys
from setuptools import setup, find_packages


# Make sure the user can install poold.in code
username = os.environ.get('POOLDCODE_AUTH_USERNAME')
password = os.environ.get('POOLDCODE_AUTH_PASSWORD')

if not username:
    raise RuntimeError('A username is required to install poold.in packages')

if not password:
    raise RuntimeError('A password is required to install poold.in packages')


# Enforce python 2.7
py = sys.version_info[:2]

if py > (2, 7) or py < (2, 7):
    raise RuntimeError('Python 2.7 is required')


# Specify non-pypi dependency links (i.e. locate poold.in and github packages)
pooldin = 'http://%s:%s@code.poold.in/pypi/%s/' % (username, password, '%s')
github = 'https://github.com/%s'

links = [
    pooldin % 'pooldlib/#egg==pooldlib',
    github % 'maxcountryman/flask-login/tarball/master#egg=flask-login',
]


# Required dependencies
required = [
    'PyYAML==3.10',
    'gunicorn==0.14.6',
    'yuicompressor==2.4.7',
    'itsdangerous==0.17',
    'pooldlib==0.1-dev.1350681899.e2966cf',
    'flask==0.9',
    'flask-gravatar==0.2.3',
    'flask-wtf==0.8',
    'flask-login',
    'flask-assets',
]


# Testing dependencies
tests = [
    'pep8',
    'nose==1.2.1',
    'mock==1.0.0',
    'coverage==3.5.2',
]


# Documentation dependencies
docs = [
    'Sphinx==1.1.3',
]


# Development dependencies
dev = [
    'readline==6.2.2',
    'ipython==0.13',
    'bpython==0.11',
]


setup(name='pooldwww',
      version='0.1',
      description='The poold.in www website',
      long_description=__doc__,
      keywords='library',
      author='Poold.in',
      author_email='dev@poold.in',
      url='http://poold.in',
      license='PRIVATE',
      packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
      include_package_data=True,
      zip_safe=False,
      extras_require=dict(tests=tests, docs=docs, dev=dev),
      install_requires=required,
      dependency_links=links,
      entry_points=dict(),
      scripts=[],
      classifiers=[
          'Development Status :: 4 - Beta',
          'Intended Audience :: Poold.in'
      ])
