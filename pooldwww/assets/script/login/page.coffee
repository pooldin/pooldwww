class PI.pages.Login extends PI.pages.Page

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
