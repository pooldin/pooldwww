class PI.forms.Validator

  constructor: (config) ->
    config ?= {}
    @config = config
    @name = config.name if config.name
    @name ?= 'Field'

  message: (msg) ->
    return @config.message or msg or @defaultMessage()

  defaultMessage: ->
    return "Invalid #{@name.toLowerCase()}"

  validate: (value) ->
    deferred = @isValid(value)

    unless deferred is true or deferred is false
      return deferred

    return $.Deferred (resp) =>
      resp.resolve(@message()) if deferred is false
      resp.resolve() unless deferred is false

  isValid: ->
    return true


class PI.forms.Remote extends PI.forms.Validator

  constructor: (config) ->
    super(config)
    @field = config.field if config.field?
    throw 'Field name must be specified' unless @field?

    @url = @config.url if @config.url?
    throw 'Missing server url' unless @url

    @method = @config.method if @config.method?
    @method ?= 'GET'

  isValid: (value) ->
    response = $.Deferred()
    data = {}
    data[@field] = value
    request = $.ajax(@url, {
      context: this,
      data: data,
      dataType: 'json',
      type: @method
    })

    request.done ->
      response.resolve()

    request.error (xhr) ->
      if xhr.status is 403 and xhr.responseText
        response.resolve(@message(xhr.responseText))
      else
        response.resolve(@message())

    return response


class PI.forms.Required extends PI.forms.Validator

  defaultMessage: ->
    return "#{@name} is required"

  isValid: (value) ->
    return value != '' and value?


class PI.forms.Length extends PI.forms.Validator

  constructor: (config) ->
    config ?= {}
    super(config)
    @length = parseInt(config.length, 10) or 1

  defaultMessage: ->
    return "#{@name} must be #{@length} characters long"

  isValid: (value) ->
    length = value?.length
    return length >= @length


class PI.forms.MinimumLength extends PI.forms.Length

  defaultMessage: ->
    return "#{@name} must be at least #{@length} characters"

  isValid: (value) ->
    length = value?.length
    return length >= @length


class PI.forms.MaximumLength extends PI.forms.Length

  defaultMessage: ->
    return "#{@name} cannot be more than #{@length} characters"

  isValid: (value) ->
    length = value?.length
    return length <= @length


class PI.forms.Regex extends PI.forms.Validator

  constructor: (config) ->
    config ?= {}
    super(config)
    @pattern = config.pattern if config.pattern
    throw 'Invalid regex pattern' unless @pattern

  isValid: (value) ->
    return @pattern.test(value)
    length = value?.length
    return length <= @length


class PI.forms.Email extends PI.forms.Regex
  pattern: /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,6}$/i


class PI.forms.PositiveInteger extends PI.forms.Regex
  pattern: /^[0-9]+$/

  value: (value) ->
    return parseInt(value, 10)

  defaultMessage: ->
    return "#{@name} is not a positive integer"


class PI.forms.MonthInteger extends PI.forms.PositiveInteger

  isValid: (value) ->
    return false if not @pattern.test(value)
    return 0 < @value(value) < 13


class PI.forms.DayInteger extends PI.forms.PositiveInteger

  isValid: (value) ->
    return false if not @pattern.test(value)
    date = new Date()
    month = PI.page.form.date_month()
    year = PI.page.form.date_year() ? date.getFullYear()
    date = new Date(year, month, 0)
    return 0 < @value(value) <= date.getDate()


class PI.forms.YearInteger extends PI.forms.PositiveInteger

  isValid: (value) ->
    date = new Date()
    return false if not @pattern.test(value)
    return date.getFullYear() <= @value(value)


class PI.forms.Integer extends PI.forms.Regex
  pattern: /^\-?[0-9]+$/

  value: (value) ->
    return parseInt(value, 10)

  defaultMessage: ->
    return "#{@name} is not an integer"


class PI.forms.Equal extends PI.forms.Validator

  constructor: (config) ->
    config ?= {}
    super(config)
    @callback = config.callback if config.callback
    throw 'Callback is not a function' unless $.isFunction(@callback)

  defaultMessage: ->
    return "#{@name} is not equal"

  isValid: (value) ->
    return @callback() is value


class PI.forms.NotEqual extends PI.forms.Equal

  defaultMessage: ->
    return "#{@name} cannot be equal"

  isValid: (value) ->
    return not super(value)


class PI.forms.ContainsNumber extends PI.forms.Regex
  pattern: /\d/i

  defaultMessage: ->
    return "#{@name} must contain a number"


class PI.forms.ContainsLowerLetter extends PI.forms.Regex
  pattern: /[a-z]/i

  defaultMessage: ->
    return "#{@name} must contain a lowercase letter"


class PI.forms.AlphaNumeric extends PI.forms.Regex
  pattern: /^[a-z0-9]+$/i

  defaultMessage: ->
    return "#{@name} can only contain numbers and letters"
