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

class PI.pages.PoolViewPage extends PI.pages.Page

  constructor: (config) ->
    config ?= {}
    @tabs = {}
    @title = config.title or "Pool"
    @amount = ko.observable(config.amount or 0).extend(money: precision: 2)
    @contributionAmount = ko.observable(config.contributionAmount or 0).extend(money: precision: 2)
    @participants = ko.observableArray()
    _participants = config.participants or []
    for participant in _participants
      @participants.push(participant)
    @participantCount = ko.computed(@countParticipants)

    @date = new Date()
    @date.setTime(config.timestamp * 1000)
    @daysRemaining = ko.computed(@calculateDaysRemaining)
    @hoursRemaining = ko.computed(@calculateHoursRemaining)
    @minutesRemaining = ko.computed(@calculateMinutesRemaining)

    tabs = config.tabs or {}
    for tab_id, tab of tabs
      $(tab_id + ' a').click(@onTabClick)
      $(tab_id + ' a[data-toggle="tab"]').on('shown', @onShow)
      visible = true
      for t in tab
        @tabs[t] = new PI.pages.Tab({
          visible: visible, # there has to be a better way...
          link: t
        })
        visible = false # there has to be a better way...
        $(tab_id + ' a:first').tab('show')

  onTabClick: (e) ->
    e.preventDefault()
    $(this).tab('show')

  onShow: (e) =>
    @tabs[e.target.hash].show()
    @tabs[e.relatedTarget.hash].hide() if e.relatedTarget

  countParticipants: =>
    return @participants().length

  calculateDaysRemaining: =>
    now = new Date()
    return parseInt((@date - now) / (3600000 * 24))

  calculateHoursRemaining: =>
    now = new Date()
    return parseInt(((@date - now) - @calculateDaysRemaining()*(3600000 * 24)) / 3600000)

  calculateMinutesRemaining: =>
    now = new Date()
    return parseInt(((@date - now) - @calculateDaysRemaining()*(3600000 * 24) - (@calculateHoursRemaining()*3600000)) / 60000)

