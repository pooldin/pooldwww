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
    @form.saved.add(@onLogin, this)

  title: ->
    return @form.error() or @config.title

  onLogin: (form, xhr) ->
    window.location = xhr.getResponseHeader('location')
