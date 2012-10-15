class PI.Page

  @init: (opts) ->
    page = PI.page = new this(opts)
    page.render()
    return page

  constructor: (opts) ->
    opts ?= {}

  render: ->
    ko.applyBindings(this)
    return this

