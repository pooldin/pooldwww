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
      name: 'date_year',
      label: 'YYYY',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.YearInteger(),
      ]

    @field
      name: 'date_month',
      label: 'MM',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.MonthInteger()
      ]

    @field
      name: 'date_day',
      label: 'DD',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.DayInteger({yearField: @date_year, monthField: @date_month})
      ]

    @field
      name: 'amount',
      label: 'amount',
      validators: [
        new PI.forms.Required(),
        new PI.forms.PositiveInteger()
      ]

    @field
      name: 'contribution',
      label: 'contribution',
      validators: [
        new PI.forms.Required(),
        new PI.forms.PositiveInteger()
      ]

    @field
      name: 'required_contribution',
      label: 'required_contribution',
      value: false

    @field
      name: 'fund_collection',
      label: 'fund_collection',
      value: 'continue',
      validators: [
        new PI.forms.Required(),
      ]

    @field
      name: 'disburse_funds',
      label: 'disburse_funds',
      value: 'immediately',
      validators: [
        new PI.forms.Required(),
      ]

    @field
      name: 'date'
      label: 'date',
      value: ko.computed(@dateValue, this)
      validators: [
        new PI.forms.Required(),
        new PI.forms.FutureTimestamp(),
      ]

    @field
      name: 'milestones'
      label: 'milestones',
      value: ko.observable([])

  dateValue: ->
    year = @date_year()
    month = @date_month()
    day = @date_day()
    return if not year? or not month? or not day?
    date = new Date(year, month - 1, day)
    return parseInt(date.getTime())


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
