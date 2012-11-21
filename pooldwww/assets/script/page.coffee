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


class PI.pages.Tab

  constructor: (config) ->
    config ?= {}
    @visible = ko.observable(config.visible or false)
    @link = config.link
    @activeClass = config.activeClass or 'icon-chevron-down'
    @inactiveClass = config.activeClass or 'icon-chevron-up'
    @indicatorEL = $("a[href='" + @link + "'] i")

  show: ->
    @visible(true)
    @indicatorEL.removeClass(@inactiveClass)
    @indicatorEL.addClass(@activeClass)

  hide: ->
    @visible(false)
    @indicatorEL.removeClass(@activeClass)
    @indicatorEL.addClass(@inactiveClass)


class PI.pages.TabbedContent

  constructor: (tabs) ->
    @tabs = {}
    tabs = tabs or {}
    for tab_id, tab of tabs
      jQuery(tab_id + ' a').click(@onTabClick)
      jQuery(tab_id + ' a[data-toggle="tab"]').on('shown', @onShow)
      visible = true
      for t in tab
        @tabs[t] = new PI.pages.Tab({
          visible: visible, # there has to be a better way...
          link: t
        })
        visible = false # there has to be a better way...
        $(tab_id + ' a:first').tab('show')

  tab: (tab) ->
    return @tabs[tab] or undefined

  onTabClick: (e) ->
    e.preventDefault()
    $(this).tab('show')

  onShow: (e) =>
    @tabs[e.target.hash].show()
    @tabs[e.relatedTarget.hash].hide() if e.relatedTarget


class PI.pages.StickyBar

  constructor: (config) ->
    return unless config
    @el = jQuery(config.selector)
    @parent = @el.parent()
    @minYPosition = config.minYPosition or 40
    @yOffset = config.yOffset or 0
    @isFixed = false
    @spacerEL = jQuery("<div class='sticky-bar-spacer' style='height: #{@el.outerHeight()}px'></div>")

    w = jQuery(window)
    w.scroll(@onScroll)
    w.resize(@onResize)

  onScroll: =>
    parentOffset = jQuery(window).scrollTop()
    if @minYPosition < parentOffset
      if not @isFixed
        @parent.prepend(@spacerEL)
      @isFixed = true
      style =
        position: 'fixed',
        top: @minYPosition + @yOffset,
        width: @parent.innerWidth(),
        zIndex: 1000
      @el.css(style)
    if @minYPosition > parentOffset
      if @isFixed
        @spacerEL.remove()
      @isFixed = false
      style =
        position: '',
        top: '',
        width: ''
        zIndex: ''
      @el.css(style)

  onResize: =>
    if @isFixed
      @el.css({width: @parent.innerWidth()})
