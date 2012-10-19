class PI.pages.Signup extends PI.pages.Page

  constructor: (config) ->
    config ?= {}

    @config = config

    @form = new PI.forms.SignupForm({
      email: config.email,
      username: config.username
    })

    @title = ko.computed(@title, this)

  title: ->
    return @form.error() or @config.title

  submit: ->
    return if @error()
    data = @dumpForm()
    jQuery.post('/signup', data, undefined, 'json')
          .done(@onSuccess)
          .fail(@onError)

  onSuccess: (data) ->

  onError: ->
