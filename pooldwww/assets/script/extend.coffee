ko.extenders.money = (target, opts={}) ->
  return ko.computed
    read: ->
      number = target()
      return unless number? and not isNaN(number)
      return accounting.formatMoney(number, opts)

    write: (value) ->
      current = target()
      target(value) unless value is current


ko.extenders.number = (target, opts={}) ->
  return ko.computed
    read: ->
      number = target()
      return unless number? and not isNaN(number)
      return accounting.formatMoney(number, opts)

    write: (value) ->
      current = target()
      target(value) unless value is current


ko.extenders.validate = (target, opts=[]) ->
  exists = target.validate?
  target.errors ?= ko.observableArray([])
  target.error ?= ko.computed -> target.errors()?[0]
  target.validators ?= []

  for validator in opts
    index = target.validators.indexOf(validator)
    target.validators.push(validator) if index < 0

  target.validate ?= (value) ->
    errors = []
    for v in target.validators
      errors = errors.concat(v.errors(value ? target()))
    target.errors(errors)
    return errors

  target.subscribe(target.validate) unless exists
  return target


ko.extenders.track = (target, enabled) ->
  target.tracking = enabled != false

  target.history ?= ko.observableArray([target()])

  target.previous ?= ko.computed ->
    return target.history()?[0]

  target.dirty ?= ko.computed ->
    return target() is target.history()?[0]

  target.commit ?= ->
    value = target()
    target.history.unshift(target()) if target.history.indexOf(value) != 0
    return target


ko.extenders.mailcheck = (target, opts) ->
  opts = {} if opts is true

  exists = target.mailcheck?
  target.mailcheck ?= ko.observable()

  target.mailcheck.options = $.extend(target.mailcheck.options ? {}, opts ? {})
  unless target.mailcheck.options.topLevelDomains
    tlds = ["co.uk", "com", "net", "org", "info", "edu", "gov", "mil", "in", "io", "ca", "us"]
    target.mailcheck.options.topLevelDomains = tlds

  target.mailcheck.options.suggested ?= (suggestion) ->
    suggestion = suggestion.full
    value = target.mailcheck()
    target.mailcheck(suggestion) unless suggestion is value

  target.mailcheck.options.empty ?= ->
    target.mailcheck(undefined) if target.mailcheck()?

  unless exists
    target.subscribe (value) ->
      args = $.extend({}, target.mailcheck.options, email: value)
      Kicksend.mailcheck.run(args)

  target.mailcheck.accept ?= ->
    suggestion = target.mailcheck()
    target(suggestion) unless target() is suggestion
    target.mailcheck.reject()
    return target

  target.mailcheck.reject ?= ->
    target.mailcheck(undefined) if target.mailcheck()?
    return target
