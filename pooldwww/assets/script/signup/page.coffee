class PI.pages.Signup extends PI.pages.Page

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
