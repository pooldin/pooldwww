"""
pooldwww
========

This is the poold.in website. It currently depends on the pooldb and the
pooldlib projects for database management and common code.

More to come as the news develops.
"""

from setuptools import setup, find_packages
import sys

py = sys.version_info[:2]

if py > (2, 7) or py < (2, 7):
    raise RuntimeError('Python 2.7 is required')


required = [
    'PyYAML==3.10',
    'gunicorn==0.14.6',
    'yuicompressor==2.4.7',
    'webassets',
    'pooldlib==0.1',
    'flask==0.9',
    'flask-gravatar==0.2.3',
    'flask-wtf==0.8',
    'flask-login',
    'flask-assets',
]

github = 'https://github.com/%s'

deps = [
    github % 'maxcountryman/flask-login/tarball/master#egg=Flask-Login',
    github % 'miracle2k/flask-assets/tarball/master#egg=Flask-Assets',
    github % 'miracle2k/webassets/tarball/master#egg=webassets',
]

tests = [
    'nose==1.2.1',
    'mock==1.0.0',
    'coverage==3.5.2',
]

docs = [
    'Sphinx==1.1.3',
]

meta = [
    'Development Status :: 4 - Beta',
    'Intended Audience :: Poold.in'
]

setup(name='pooldwww',
      version='0.1dev',
      description='The poold.in www website',
      long_description=__doc__,
      keywords='library',
      author='Brian Oldfield',
      author_email='brian@poold.in',
      url='http://poold.in',
      license='PRIVATE',
      packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
      include_package_data=True,
      zip_safe=True,
      extras_require=dict(tests=tests, docs=docs),
      install_requires=required,
      dependency_links=deps,
      entry_points=dict(),
      scripts=[],
      classifiers=meta)
