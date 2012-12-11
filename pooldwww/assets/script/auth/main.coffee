class PI.pages.MainAuthPage extends PI.pages.Page

  constructor: (config) ->
    @config = config

    @loginForm = new PI.forms.LoginForm({
      login: config.username
    })
    @loginForm.saved.add(@onSaved, this)

    @signupForm = new PI.forms.SignupForm({
      email: config.email,
      username: config.username
    })
    @signupForm.saved.add(@onSaved, this)

    @loginTitle = ko.computed(@loginTitle, this)
    @loginSubmitText = ko.computed(@loginSubmitText, this)

    @signupTitle = ko.computed(@signupTitle, this)
    @signupSubmitText = ko.computed(@signupSubmitText, this)

    @tabbedContent = new PI.pages.TabbedContent(config.tabs or {})

    if config.showSignup
      jQuery('a[href="#signup"]').click()

  signupTitle: ->
    return @signupForm.error() or @config.signupTitle

  loginTitle: ->
    return @loginForm.error() or @config.loginTitle

  loginSubmitText: ->
    return 'Logging in...' if @loginForm.saving()
    return 'Suit up!'

  signupSubmitText: ->
    return 'Creating account...' if @signupForm.saving()
    return 'Dive In!'

  onSaved: (form, xhr) ->
    window.location = xhr.getResponseHeader('location')

  tabs: (tab) ->
    return @tabbedContent.tab(tab)
