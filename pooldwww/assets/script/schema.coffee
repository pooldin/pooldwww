class PI.Schema
  constructor: (cls, mapping) ->
    unless jQuery.isFunction(cls)
      mapping = cls
      cls = undefined

    @model = cls
    @mapping = mapping ? {}

  key: (key, callback) ->
    if key and callback
      @mapping[key] ?= {}
      @mapping[key].key = callback
    return this

  map: (key, callback) ->
    if key and callback
      @mapping[key] ?= {}
      @mapping[key].create = callback
      @mapping[key].update = callback
    return this

  mapMoment: (keys...) ->
    for key in keys
      @map key, (context) ->
        m = moment(context.data)
        return m if context.observable
        return ko.observable(m)

  update: (key, callback) ->
    if key and callback
      @mapping[key] ?= {}
      @mapping[key].update = callback
    return this

  addList: (key, args...) ->
    return this unless args.length > 0

    @mapping[key] ?= []

    for arg in args
      if jQuery.isArray(arg)
        arg = arg.slice()
        arg.unshift(key)
        @addList.apply(this, arg)
      else
        @mapping[key].push(arg)

    delete @mapping[key] if @mapping[key].length < 1
    return this

  ignore: (args...) ->
    args.unshift('ignore')
    @addList.apply(this, args)
    return this

  include: (args...) ->
    args.unshift('include')
    @addList.apply(this, args)
    return this

  copy: (args...) ->
    args.unshift('copy')
    @addList.apply(this, args)
    return this

  load: (data, viewModel) ->
    viewModel = @model() if not viewModel and @model

    return ko.mapping.fromJS(data, @mapping) unless viewModel

    ko.mapping.fromJS(data, @mapping, viewModel)
    return viewModel

  dump: (viewModel) ->
    return ko.mapping.toJS(viewModel) if viewModel


PI.schema = new PI.Schema()


class PI.Model

  @load: (data) ->
    return new this(data)

  constructor: (data) ->
    @schema = @constructor.schema ? PI.schema
    @schema.load(data, this)

  update: (data) ->
    @schema.load(data, this)
    return this

  dump: ->
    return @schema.dump(this)

  toJSON: ->
    return ko.toJSON(@schema.dump(this))
