import socket
import smtplib
from flask import current_app
from pooldlib.api.communication import Email, HTMLEmail
from pooldlib import exceptions as exc


def init_app(app):
    Emailer(app)


class Emailer(object):

    def __init__(self, app=None):
        if app:
            self.app = app
            self.init_app(app)

    def init_app(self, app):
        app.emailer = self

    def message(self, app=None, **kw):
        app = app or getattr(self, 'app', None)
        app = app or current_app
        return Message(app.config.get('EMAIL_HOST'),
                       app.config.get('EMAIL_PORT'),
                       username=app.config.get('EMAIL_USERNAME'),
                       password=app.config.get('EMAIL_PASSWORD'),
                       sender=app.config.get('EMAIL_SENDER'),
                       **kw)

    def send_text(self, subject, text, recipients, ccs=None, bccs=None, disclose_recipients=True):
        return self.message(subject=subject,
                            text=text,
                            recipients=recipients,
                            cc_recipients=ccs,
                            bcc_recipients=bccs).send(disclose_recipients=disclose_recipients)

    def send_html(self, subject, html, text, recipients, ccs=None, bccs=None, disclose_recipients=True):
        return self.message(subject=subject,
                            html=html,
                            text=text,
                            recipients=recipients,
                            cc_recipients=ccs,
                            bcc_recipients=bccs).send(disclose_recipients=disclose_recipients)


class Message(object):

    def __init__(self, host, port, username=None,
                                   password=None,
                                   sender=None,
                                   subject=None,
                                   text=None,
                                   html=None,
                                   recipients=None,
                                   cc_recipients=None,
                                   bcc_recipients=None):
        if not host:
            raise ValueError('Invalid email host')

        if not port:
            raise ValueError('Invalid email port')

        if username and not password:
            msg = 'Email username specified but password was not'
            raise ValueError(msg)

        if password and not username:
            msg = 'Email password specified but username was not'
            raise ValueError(msg)

        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.subject = subject
        self.sender = sender
        self.text = text
        self.html = html
        self.recipients = []
        self.cc_recipients = []
        self.bcc_recipients = []

        if recipients:
            self.recipients = recipients
        if cc_recipients:
            self.cc_recipients = cc_recipients
        if bcc_recipients:
            self.bcc_recipients = bcc_recipients

    def send(self, disclose_recipients=True):
        if self.html:
            email = HTMLEmail(self.host, self.port, sender=self.sender, disclose_recipients=disclose_recipients)
            email.set_content(self.html, self.text)
        else:
            email = Email(self.host, self.port, sender=self.sender, disclose_recipients=disclose_recipients)
            email.set_content(self.text)

        email.set_subject(self.subject)
        email.add_recipients(self.recipients)

        if self.bcc_recipients:
            for recipient in self.bcc_recipients:
                email.add_bcc(recipient)

        if self.cc_recipients:
            for recipient in self.cc_recipients:
                email.add_cc(recipient)

        try:
            email.connect()
        except (socket.gaierror, smtplib.SMTPHeloError):
            return False

        if self.username and self.password:
            try:
                email.login(self.username, self.password)
            except (smtplib.SMTPException,
                    smtplib.SMTPHeloError,
                    smtplib.SMTPAuthenticationError):
                return False

        try:
            email.send()
        except (smtplib.SMTPHeloError,
                smtplib.SMTPRecipientsRefused,
                smtplib.SMTPSenderRefused,
                smtplib.SMTPDataError,
                exc.SMTPConnectionNotInitilizedError,
                exc.NoContentEmailError,
                exc.NoEmailRecipientsError,
                exc.GoWorkForBallmerError):
            return False
        finally:
            email.disconnect()
        return True
