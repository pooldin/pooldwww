class PI.forms.ProfileForm extends PI.forms.Form

  endpoint: '/settings/profile'

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


class PI.pages.ProfilePage extends PI.pages.Page

  constructor: (config) ->
    @error = ko.observable(false)
    @success = ko.observable(false)
    @title = ko.computed(@title, this)

    @form = new PI.forms.ProfileForm(config)
    @form.saved.add(@onSaved, this)
    @form.failed.add(@onFailed, this)

  title: ->
    return 'Your Profile was Saved Successfully!' if @success() is true
    return 'Your Profile was not Saved!' if @error() is true
    return 'Your Profile'

  onSaved: ->
    @success(true)
    setTimeout((() => @success(undefined)), 5000)

  onFailed: ->
    @error(true)
    setTimeout((() => @error(undefined)), 5000)
