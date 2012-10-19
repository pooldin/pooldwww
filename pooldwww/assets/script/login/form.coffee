class PI.forms.LoginForm extends PI.forms.Form

  endpoint: '/login' + (location?.search ? '')

  init: (config) ->
    @field
      name: 'login',
      value: config.login,
      validators: [new PI.forms.Required(name: 'Login')]

    @field
      name: 'password',
      validators: [new PI.forms.Required(name: 'Password')]
