class PI.forms.ProfileForm extends PI.forms.Form

  endpoint: '/settings/profile'

  init: (config) ->
    @field
      name: 'name',
      value: config.name,
      validators: [new PI.forms.Required(name: 'Name')]

    @field
      name: 'username',
      value: config.username,
      validators: [
        new PI.forms.Required(name: 'Username'),
        new PI.forms.MinimumLength(name: 'Username', length: 2)
        new PI.forms.AlphaNumeric(name: 'Username')
      ]

    @field
      name: 'email',
      value: config.email,
      validators: [
        new PI.forms.Required(name: 'Email'),
        new PI.forms.Email(name: 'Email')
      ]
