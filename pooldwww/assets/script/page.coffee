PI.pages ?= {}


class PI.pages.Page

  @init: (opts) ->
    page = PI.page = new this(opts)
    page.render()
    return page

  constructor: (opts) ->
    opts ?= {}

  render: ->
    ko.applyBindings(this)
    return this


class PI.pages.Screen

  constructor: (config) ->
    config ?= {}
    @visible = ko.observable(config.visible or false)
    @screenID = config.screenID
    @indicatorEL = config.indicatorEL
    @el = $(@screenID)

    @show() if @visible()
    @hide() if not @visible()

  show: ->
    @visible(true)
    @el.removeClass('inactive-screen')
    @el.addClass('active-screen')
    @indicatorEL.removeClass('inactive-indicator')
    @indicatorEL.addClass('active-indicator')

  hide: ->
    @visible(false)
    @el.removeClass('active-screen')
    @el.addClass('inactive-screen')
    @indicatorEL.removeClass('active-indicator')
    @indicatorEL.addClass('inactive-indicator')


class PI.pages.Screeninator

  constructor: (config) ->
    config ?= {}
    screens = config.screens or []

    @screeninatorEL = $('#screeninator .indicators')

    @containedScreens = []
    first = screens.shift()
    firstIndicatorEl = $('<span class="dot">&nbsp;</span>')
    @screeninatorEL.append(firstIndicatorEl)

    for screenID in screens
      indicatorEL = $('<span class="dot">&nbsp;</span>')
      s = new PI.pages.Screen({
        visible: false,
        screenID: screenID,
        indicatorEL: indicatorEL
      })
      @containedScreens.push(s)
      @screeninatorEL.append(indicatorEL)

    s = new PI.pages.Screen({
      visible: true,
      screenID: first,
      indicatorEL: firstIndicatorEl
    })
    @containedScreens.push(s)

  nextScreen: (e) =>
    current = @containedScreens.pop()
    current.hide()
    next = @containedScreens.shift()
    next.show()
    @containedScreens.push(current)
    @containedScreens.push(next)

  previousScreen: (e) =>
    current = @containedScreens.pop()
    current.hide()
    previous = @containedScreens.pop()
    previous.show()
    @containedScreens.unshift(current)
    @containedScreens.push(previous)
