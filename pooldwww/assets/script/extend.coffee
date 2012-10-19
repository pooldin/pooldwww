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
