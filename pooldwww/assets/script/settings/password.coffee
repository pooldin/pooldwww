class PI.forms.ChangePasswordForm extends PI.forms.Form

  endpoint: '/settings/password'

  init: (config) ->
    @field
      name: 'oldPassword',
      validators: [new PI.forms.Required(name: 'Old password')]

    @field
      name: 'newPassword',
      validators: [
        new PI.forms.Required(name: 'New password'),
        new PI.forms.MinimumLength(name: 'New password', length: 7),
        new PI.forms.ContainsNumber(name: 'New password')
        new PI.forms.ContainsLowerLetter(name: 'New password')
      ]

    @field
      name: 'newPasswordConfirm',
      validators: [
        new PI.forms.Equal({
          message: 'Passwords do not match',
          callback: @newPassword
        })
      ]
