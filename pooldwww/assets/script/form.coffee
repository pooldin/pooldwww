PI.forms ?= {}

class PI.forms.Form
  constructor: (config) ->
    config ?= {}
    @config = config
    @fields = []

    @saving = new signals.Signal()
    @saved = new signals.Signal()
    @failed = new signals.Signal()

    @processing = ko.observable(false)
    @invalids = ko.observableArray([])
    @errors = ko.observableArray([])
    @errors.subscribe => @error(@firstError())
    @error = ko.observable(config.error or @firstError())

    @invalids.subscribe(@populateErrors, this)
    @invalid = ko.computed(@firstInvalid, this)

    @isValid = ko.computed(@isValid, this)
    @init(config)

  populateInvalid: ->
    return if @_validating

    invalids = []

    for field in @fields
      if @[field].errors().length > 0
        invalids.push(@[field])

    @invalids(invalids)

  firstInvalid: ->
    return @invalids()?[0]

  populateErrors: (invalids) ->
    errors = []
    for invalid in invalids ? @invalid()
      errors = errors.concat(invalid.errors())
    @errors(errors)

  firstError: ->
    return @errors?()[0]

  isValid: (field) ->
    return @errors().length < 1 unless field?
    field = @[field] unless $.isFunction(field)
    return false unless field?
    return @invalids.indexOf(field) < 0

  isInvalid: (field) ->
    field = @[field] unless $.isFunction(field)
    return @invalid() is field

  field: (config) ->
    config ?= {}

    throw 'Invalid field name' unless config.name
    name = config.name
    value = config.value ? config.default

    @fields.push(config.name) unless @fields.indexOf(config.name) > -1

    exists = @[name]?
    @[name](value) if exists
    @[name] = ko.observable(value) unless exists
    @[name].extend(validate: config.validators) if config.validators
    @[name].errors.subscribe(@populateInvalid, this) unless exists
    return @[name]

  validate: ->
    return if @_validating
    @_validating = true
    for field in @fields
      @[field].validate()
      break if @[field].error()
    @_validating = false
    @populateInvalid()
    return @errors().length < 1

  submit: =>
    @save() if @validate()
    return this

  save: ->
    @saving.dispatch(this)
    @processing(true)
    $.post(@endpoint, @todict(), undefined, 'json')
     .done(@onSuccess)
     .fail(@onError)

  onSuccess: (value, message, xhr) =>
    @processing(false)
    @saved.dispatch(this, value)

  onError: (xhr, message, value) =>
    @processing(false)
    @error(xhr.responseText or 'An error occurred')
    @failed.dispatch(this, xhr.responseText)

  todict: (args...) ->
    fields = []
    dict = {}

    if args.length < 1
      fields = @fields
    else
      for arg in args
        fields.push(arg) if @fields.indexOf(arg) > -1
      return dict if fields.length < 1

    for field in fields
      value = @[field]()
      dict[field] = value if value?

    return dict
