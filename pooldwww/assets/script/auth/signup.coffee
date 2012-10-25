class PI.forms.SignupForm extends PI.forms.Form

  endpoint: '/signup' + (location?.search ? '')

  init: (config) ->
    @field
      name: 'email',
      label: 'Email',
      value: config.email,
      validators: [
        new PI.forms.Required(),
        new PI.forms.Email()
        new PI.forms.Remote(url: '/verify/email', field: 'email')
      ]

    @email.extend(mailcheck: true)

    @field
      name: 'username',
      label: 'Username',
      value: config.username,
      validators: [
        new PI.forms.Required(),
        new PI.forms.MinimumLength(length: 2)
        new PI.forms.AlphaNumeric()
        new PI.forms.Remote(url: '/verify/username', field: 'username')
      ]

    @field
      name: 'password',
      label: 'Password',
      validators: [
        new PI.forms.Required(),
        new PI.forms.MinimumLength(length: 7),
        new PI.forms.ContainsNumber()
        new PI.forms.ContainsLowerLetter()
      ]

    @field
      name: 'password_confirm',
      label: 'Confirm Password',
      validators: [
        new PI.forms.Equal({
          message: 'Passwords do not match',
          callback: @password
        })
      ]


class PI.pages.SignupPage extends PI.pages.Page

  constructor: (config) ->
    config ?= {}

    @config = config

    @form = new PI.forms.SignupForm({
      email: config.email,
      username: config.username
    })

    @form.saved.add(@onSignup, this)
    @title = ko.computed(@title, this)

  title: ->
    return @form.error() or @config.title

  onSignup: (form, xhr) ->
    window.location = xhr.getResponseHeader('location')
