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
