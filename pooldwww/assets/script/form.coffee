PI.forms ?= {}

class PI.forms.Field

  constructor: (config) ->
    config ?= {}
    @config = config

    @name = config.name if config.name?
    throw 'A field must have a name' unless @name

    if ko.isObservable(config.value)
      @value = config.value
    else
      @value = ko.observable(config.value) if config.value?
      @value = ko.observable(@default) unless config.value?

    @label = config.label if config.label?
    @default = config.default if config.default?
    @error = ko.observable()
    @value.error = @error
    @errors = ko.observableArray([])
    @errors.subscribe(@onErrors, this)
    @value.errors = @errors
    @valid = ko.observable()
    @value.valid = @valid
    @validating = ko.observable()
    @value.validating = @validating
    @value.field = this
    @value.validate = => @validate()

    @validators = config.validators ? []
    (validator.name = @label for validator in @validators) if @label

    @value.subscribe(@onChanged, this)

  validate: (value, validators, deferred) ->
    deferred ?= $.Deferred()

    if arguments.length is 0 and @valid()?
      deferred.resolve(this)
      return deferred

    value ?= @value()
    validators ?= @validators.slice()

    if validators.length < 1
      @validating(false) if @validating()
      @errors([])
      deferred.resolve(this)
      return deferred

    @validating(true) unless @validating()
    validator = validators.shift()
    validator.validate(value).done (error) =>
      if error
        @validating(false) if @validating()
        @errors([error])
        deferred.resolve(this)
      if not error and @validating
        @validate(value, validators, deferred)

    return deferred

  onErrors: (errors) ->
    errors ?= @errors()
    error = errors?[0]
    @error(error)
    @valid(not error?)

  onChanged: (value) ->
    return if @validating() or @defaulting
    value ?= @value()

    if @default? and ((not value?) or value is '')
      @defaulting = true
      value = @default
      @value(@default)
      @defaulting = false

    @validate(value)


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
    @invalid = ko.observable()
    @errors = ko.observableArray([])
    @error = ko.observable()

    @invalids.subscribe (invalids) =>
      @invalid(invalids?[0])
      @populateErrors()

    @errors.subscribe (errors) =>
      @error(errors?[0])

    @init(config)

  populateInvalid: ->
    return if @_validating
    invalids = (@[f] for f in @fields when @[f].error())
    @invalids(invalids)

  populateErrors: (invalids) ->
    return if @_validating
    invalids ?= @invalids()
    errors = (i.error() for i in invalids)
    @errors(errors)

  isInvalid: (field) ->
    return @invalid() is @[field] if @[field]?
    return @invalid() is field

  field: (field) ->
    unless field instanceof PI.forms.Field
      field = new PI.forms.Field(field)

    @fields.push(field.name) unless @fields.indexOf(field.name) > -1

    exists = @[field.name]?
    @[field.name] = field.value unless exists
    @[field.name].error.subscribe(@populateInvalid, this) unless exists
    return @[field.name]

  validate: ->
    return if @_validating
    @_validating = true
    deferred = $.Deferred()
    deferreds = (@[field].validate() for field in @fields)
    $.when.apply($, deferreds).done =>
      @_validating = false
      @populateInvalid()
      deferred.resolve(@invalids().length < 1)
    return deferred

  submit: =>
    @validate().done (valid) =>
      return unless valid
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
      @saved.dispatch(this, xhr, value)

    callback() if @responseDelay > -1
    setTimeout(callback, @responseDelay) unless @responseDelay > -1

  onError: (xhr, message, value) =>
    callback = =>
      @_saving = false
      @processing(false)
      txt = 'An error occurred'
      txt = xhr.responseText if xhr.status is 403
      @error(txt)
      @failed.dispatch(this, xhr, value)

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
