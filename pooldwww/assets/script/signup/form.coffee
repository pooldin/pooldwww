class PI.forms.SignupForm extends PI.forms.Form

  endpoint: '/signup' + (location?.search ? '')

  init: (config) ->
    @field
      name: 'email',
      label: 'Email',
      value: config.email,
      validators: [
        new PI.forms.Required(),
        new PI.forms.Email()
        new PI.forms.Remote(url: '/verify/email', field: 'email')
      ]

    @email.extend(mailcheck: true)

    @field
      name: 'username',
      value: config.username,
      validators: [
        new PI.forms.Required(name: 'Username'),
        new PI.forms.MinimumLength(name: 'Username', length: 2)
        new PI.forms.AlphaNumeric(name: 'Username')
        new PI.forms.Remote(url: '/verify/username', field: 'username')
      ]

    @field
      name: 'password',
      validators: [
        new PI.forms.Required(name: 'Password'),
        new PI.forms.MinimumLength(name: 'Password', length: 7),
        new PI.forms.ContainsNumber(name: 'Password')
        new PI.forms.ContainsLowerLetter(name: 'Password')
      ]

    @field
      name: 'password_confirm',
      validators: [
        new PI.forms.Equal({
          message: 'Passwords do not match',
          callback: @password
        })
      ]
