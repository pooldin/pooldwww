class PI.forms.PasswordResetForm extends PI.forms.Form

  endpoint: '/reset'

  init: (config) ->
    @field
      name: 'email',
      label: 'Email',
      value: config.email,
      validators: [
        new PI.forms.Required(),
        new PI.forms.Email()
      ]

    @email.extend(mailcheck: true)


class PI.forms.PasswordChangeForm extends PI.forms.Form

  endpoint: '/reset' + (location?.search ? '')

  init: (config) ->
    @field
      name: 't',
      label: 'Token',
      value: config.token,
      validators: [
        new PI.forms.Required()
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
      label: 'Password Confirm',
      validators: [
        new PI.forms.Required(),
        new PI.forms.Equal({
          message: 'Passwords do not match',
          callback: @password
        })
      ]


class PI.pages.PasswordResetPage extends PI.pages.Page

  constructor: (config) ->
    @config = config

    @form = new PI.forms.PasswordResetForm({
      email: config.email
    })

    @title = ko.computed(@title, this)
    @submitText = ko.computed(@submitText, this)
    @sent = ko.observable(false)
    @form.saved.add(@onSaved, this)

  title: ->
    return @form.error() or @config.title

  submitText: ->
    return 'Sending Email...' if @form.saving()
    return 'Help a swimmer out!'

  onSaved: (form, xhr) ->
    @sent(true)


class PI.pages.PasswordChangePage extends PI.pages.Page

  constructor: (config) ->
    @config = config

    @form = new PI.forms.PasswordChangeForm({
      token: config.token
    })

    @title = ko.computed(@title, this)
    @submitText = ko.computed(@submitText, this)
    @form.saved.add(@onSaved, this)

  title: ->
    return @form.error() or @config.title

  onSaved: (form, xhr) ->
    window.location = xhr.getResponseHeader('location')

  submitText: ->
    return 'Resetting and Logging in...' if @form.saving()
    return 'Suit up!'
