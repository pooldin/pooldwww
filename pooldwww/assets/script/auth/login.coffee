class PI.forms.LoginForm extends PI.forms.Form

  endpoint: '/login' + (location?.search ? '')

  init: (config) ->
    @field
      name: 'login',
      value: config.login,
      validators: [new PI.forms.Required(name: 'Login')]

    @field
      name: 'password',
      validators: [new PI.forms.Required(name: 'Password')]

    @field
      name: 'remember',
      label: 'Remember Me',
      value:  not (not config.remember)


class PI.pages.LoginPage extends PI.pages.Page

  constructor: (config) ->
    @config = config

    @form = new PI.forms.LoginForm({
      login: config.login
    })

    @title = ko.computed(@title, this)
    @submitText = ko.computed(@submitText, this)
    @form.saved.add(@onSaved, this)

  title: ->
    return @form.error() or @config.title

  submitText: ->
    return 'Logging in...' if @form.saving()
    return 'Suit up!'

  onSaved: (form, xhr) ->
    window.location = xhr.getResponseHeader('location')
