PI.forms ?= {}

class PI.forms.Form
  autosave: true
  saveDelay: -1
  responseDelay: -1

  constructor: (config) ->
    config ?= {}
    @config = config
    @fields = []

    @autosave = @config.autosave if @config.autosave?
    @saveDelay = @config.saveDelay if @config.saveDelay?
    @responseDelay = @config.responseDelay if @config.responseDelay?

    @submitted = new signals.Signal()
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
    if @validate()
      @submitted.dispatch(this)
      @save() if @autosave
    return this

  save: ->
    return this if @_saving
    @_saving = true
    @saving.dispatch(this)
    endpoint = @endpoint
    data = @todict()
    @processing(true)
    callback = =>
      $.post(endpoint, data, undefined, 'json')
       .done(@onSuccess)
       .fail(@onError)

    callback() unless @saveDelay > -1
    setTimeout(callback, @saveDelay) if @saveDelay > -1
    return this

  onSuccess: (value, message, xhr) =>
    callback = =>
      @_saving = false
      @processing(false)
      @saved.dispatch(this, value)

    callback() if @responseDelay > -1
    setTimeout(callback, @responseDelay) unless @responseDelay > -1

  onError: (xhr, message, value) =>
    callback = =>
      @_saving = false
      @processing(false)
      @error(xhr.responseText or 'An error occurred')
      @failed.dispatch(this, xhr.responseText)

    callback() unless @responseDelay > -1
    setTimeout(callback, @responseDelay) if @responseDelay > -1

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
