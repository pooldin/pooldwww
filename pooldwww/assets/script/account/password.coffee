class PI.forms.ChangePasswordForm extends PI.forms.Form

  endpoint: '/account/password'

  init: (config) ->
    @saved.add(@empty, this)

    @field
      name: 'oldPassword',
      remote: 'old',
      label: 'Old Password',
      validators: [
        new PI.forms.Required(),
        new PI.forms.Remote({
          url: '/verify/password',
          field: 'password'
          message: 'Old Password is invalid'
        })
      ]

    @field
      name: 'newPassword',
      remote: 'new',
      label: 'New Password',
      validators: [
        new PI.forms.Required(),
        new PI.forms.MinimumLength(length: 7),
        new PI.forms.ContainsNumber(),
        new PI.forms.ContainsLowerLetter(),
        new PI.forms.NotEqual({
          message: 'New Password cannot be your old password',
          callback: @oldPassword
        })
      ]

    @field
      name: 'newPasswordConfirm',
      remote: 'confirm',
      label: 'Confirm New Password',
      validators: [
        new PI.forms.Equal({
          message: 'Confirm New Password does not match',
          callback: @newPassword
        })
      ]


class PI.pages.ChangePasswordPage extends PI.pages.Page

  constructor: ->
    @error = ko.observable(false)
    @success = ko.observable(false)
    @title = ko.computed(@title, this)

    @form = new PI.forms.ChangePasswordForm()
    @form.saved.add(@onSaved, this)
    @form.failed.add(@onFailed, this)

  title: ->
    return 'Change Password Successful!' if @success() is true
    return 'Change Password Failed!' if @error() is true
    return 'Change Password'

  onSaved: ->
    @success(true)
    setTimeout((() => @success(undefined)), 5000)

  onFailed: ->
    @error(true)
    setTimeout((() => @error(undefined)), 5000)
