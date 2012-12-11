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

    @field
      name: 'password',
      label: 'Verify Password',
      remote: 'password',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.Remote({
          url: '/verify/password',
          field: 'password'
          message: 'Password is invalid'
        })
      ]


    @email.extend(mailcheck: true)


class PI.pages.AccountDetailsPage extends PI.pages.Page

  constructor: (config) ->

    @accountForm = new PI.forms.AccountDetailsForm(config)
    @accountError = ko.observable(false)
    @accountSuccess = ko.observable(false)
    @accountForm.saved.add(@onAccountSaved, this)
    @accountForm.failed.add(@onAccountFailed, this)
    @accountFormTitle = ko.computed(@accountFormTitle, this)
    @accountFormVisible = ko.observable(true)

    @profileForm = new PI.user.ProfileForm(config)
    @profileError = ko.observable(false)
    @profileSuccess = ko.observable(false)
    @profileForm.saved.add(@onProfileSaved, this)
    @profileForm.failed.add(@onProfileFailed, this)
    @profileFormTitle = ko.computed(@profileFormTitle, this)

    @passwordForm = new PI.forms.ChangePasswordForm()
    @passwordError = ko.observable(false)
    @passwordSuccess = ko.observable(false)
    @passwordForm.saved.add(@onPasswordSaved, this)
    @passwordForm.failed.add(@onPasswordFailed, this)
    @passwordFormTitle = ko.computed(@passwordFormTitle, this)
    @passwordFormVisible = ko.observable(false)


    @tabbedContent = new PI.pages.TabbedContent(config.tabs or {})

    @isEditing = ko.observable(false)
    @displayTextPlaceholder = ko.computed(@displayTextPlaceholder, this)

    @campaigns = ko.observableArray([])
    for campaign in config.campaigns
      c = new PI.user.Campaign(campaign)
      @campaigns.push(c)

  toggleDetailsForm: (c, e) ->
    @passwordFormVisible(not @passwordFormVisible())
    @accountFormVisible(not @accountFormVisible())

  toggleProfileEdit: ->
    @isEditing(not @isEditing())
    jQuery('.about-text').focus() if @isEditing

  saveProfileEdit: ->
    text = jQuery.trim(jQuery('.about-text').text())
    changed = @profileForm.about() != text
    if changed
      @profileForm.about(text)
      @profileForm.submit()
    jQuery('.about-text').text(text)
    @toggleProfileEdit()

  cancelProfileEdit: ->
    text = @profileForm.about()
    if not text
      text = ''
    jQuery('.about-text').text(text)
    @toggleProfileEdit()

  displayTextPlaceholder: =>
    return not @isEditing() and not @profileForm.about()

  profileFormTitle: ->
    return 'Updated!' if @profileSuccess() is true and @profileForm.about()
    return 'Antisocial Badge Earned!' if @profileSuccess() is true and not @profileForm.about()
    return 'Unable to save updates.' if @profileError() is true
    return 'About'

  accountFormTitle: ->
    return 'Saved!' if @accountSuccess() is true
    return 'Unable to save updates.' if @accountError() is true
    return 'Account Details'

  passwordFormTitle: ->
    return 'Password Change Successful!' if @passwordSuccess() is true
    return 'Password Change Failed!' if @passwordError() is true
    return 'Change Password'

  onPasswordSaved: ->
    @passwordSuccess(true)
    setTimeout((() => @passwordSuccess(undefined)), 5000)

  onPasswordFailed: ->
    @passwordError(true)
    setTimeout((() => @passwordError(undefined)), 5000)

  onAccountSaved: ->
    @accountSuccess(true)
    setTimeout((() => @accountSuccess(undefined)), 5000)

  onAccountFailed: ->
    @accountError(true)
    setTimeout((() => @accountError(undefined)), 5000)

  onProfileSaved: ->
    @profileSuccess(true)
    setTimeout((() => @profileSuccess(undefined)), 5000)

  onProfileFailed: ->
    @profileError(true)
    setTimeout((() => @profileError(undefined)), 5000)

  tabs: (tab) ->
    return @tabbedContent.tab(tab)
