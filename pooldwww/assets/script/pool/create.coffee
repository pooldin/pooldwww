class PI.forms.PoolCreateForm extends PI.forms.Form

  endpoint: '/pool/create' + (location?.search ? '')

  init: (config) ->
    @field
      name: 'name',
      label: 'Pool Name',
      validators: [
        new PI.forms.Required(),
      ]

    @field
      name: 'description',
      validators: [
        new PI.forms.Required(),
      ]

    @field
      name: 'date_month',
      label: 'MM',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.MonthInteger(),
      ]

    @field
      name: 'date_day',
      label: 'DD',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.DayInteger(),
      ]

    @field
      name: 'date_year',
      label: 'YYYY',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.YearInteger(),
      ]

    @field
      name: 'amount',
      validators: [
        new PI.forms.Required(),
        new PI.forms.PositiveInteger(),
      ]

    @field
      name: 'contribution',
      validators: [
        new PI.forms.Required(),
        new PI.forms.PositiveInteger(),
      ]

    @field
      name: 'required_contribution',
      value: false

    @field
      name: 'fund_collection',
      validators: [
        new PI.forms.Required(),
      ]

    @field
      name: 'disburse_funds',
      validators: [
        new PI.forms.Required(),
      ]

    @field
      name: 'date'
      value: ko.computed(@date_value, this)
      validators: [
        new PI.forms.Required(),
      ]

    @field
      name: 'milestones'
      value: ko.observable([])

  date_value: ->
    year = @date_year()
    month = @date_month()
    day = @date_day()
    return if not year? or not month? or not day?
    date = new Date(year, month - 1, day - 1)
    return parseInt(date.getTime() / 1000)


class PI.pages.PoolCreatePage extends PI.pages.Page

  constructor: (config) ->
    config ?= {}
    @config = config

    @form = new PI.forms.PoolCreateForm({})
    @title = ko.computed(@title, this)
    @submitText = ko.computed(@submitText, this)
    @form.saved.add(@onSignup, this)

    screens = config.screens or []
    @screens = new PI.pages.Screeninator({
      screens: screens
    })

  title: ->
    return @form.error() or @config.title

  submitText: ->
    return 'Creating Pool...' if @form.saving()
    return 'Make Pool Active'

  onSignup: (form, xhr) ->
    window.location = xhr.getResponseHeader('location')
