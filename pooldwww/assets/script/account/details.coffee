class PI.forms.AccountDetailsForm extends PI.forms.Form

  endpoint: '/account/details'

  init: (config) ->
    @field
      name: 'name',
      label: 'Name',
      value: config.name

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
      name: 'email',
      label: 'Email',
      value: config.email,
      validators: [
        new PI.forms.Required(name: 'Email'),
        new PI.forms.Email(name: 'Email')
        new PI.forms.Remote(url: '/verify/email', field: 'email')
      ]

    @email.extend(mailcheck: true)


class PI.pages.AccountDetailsPage extends PI.pages.Page

  constructor: (config) ->
    @error = ko.observable(false)
    @success = ko.observable(false)
    @title = ko.computed(@title, this)

    @form = new PI.forms.AccountDetailsForm(config)
    @form.saved.add(@onSaved, this)
    @form.failed.add(@onFailed, this)

  title: ->
    return 'Account Details were Saved Successfully!' if @success() is true
    return 'Account Details were not Saved!' if @error() is true
    return 'Account Details'

  onSaved: ->
    @success(true)
    setTimeout((() => @success(undefined)), 5000)

  onFailed: ->
    @error(true)
    setTimeout((() => @error(undefined)), 5000)
