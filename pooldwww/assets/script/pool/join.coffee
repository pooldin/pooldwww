class PI.forms.ValidateCC extends PI.forms.Validator

  isValid: (value) ->
    return Stripe.validateCardNumber(value)


class PI.forms.ValidateCCV extends PI.forms.Validator

  isValid: (value) ->
    return Stripe.validateCVC(value)


class PI.forms.ValidateExpiry extends PI.forms.Validator

  isValid: (value) ->
    vals = value.split('/')
    return Stripe.validateExpiry(vals[0], vals[1])

payment = new PI.Schema()
payment.mapMoment('date')

class PI.campaign.CampaignPayment extends PI.Model

  @schema: payment

  constructor: (data) ->
    super(data)
    @year = ko.observable()
    @month = ko.observable()
    @day = ko.observable()
    @setDate()
    @formattedDate = ko.computed(@formattedDate, this)

  update: (data) =>
    super(data)
    @setDate()

  setDate: ->
    return unless @date
    @year(@date().year())
    @month(@date().month() + 1)
    @day(@date().date())

  formattedDate: ->
    return "#{@month()}/#{@day()}/#{@year()}"


class PI.pages.CampaignJoinAuthenticateScreen extends PI.pages.Page

  constructor: (config) ->
    @authCallback = config.authSuccessCallback

    @loginForm = new PI.forms.LoginForm(config)
    @loginForm.saved.add(@onAuthenticate, this)

    @loginFormVisible = ko.observable(true)
    @loginFormTitle = ko.computed(@loginFormTitle, this)
    @submitLoginText = ko.computed(@submitLoginText, this)

    @signupForm = new PI.forms.SignupForm(config)
    @signupForm.saved.add(@onAuthenticate, this)

    @signupFormVisible = ko.observable(false)
    @signupFormTitle = ko.computed(@signupFormTitle, this)
    @submitSignupText = ko.computed(@submitSignupText, this)

  showLogin: ->
    loginEl = jQuery('#pool-join-login-btn')
    loginEl.addClass('inactive')
    signupEl = jQuery('#pool-join-signup-btn')
    signupEl.removeClass('inactive')
    @loginFormVisible(true)
    @signupFormVisible(false)

  submitLoginText: ->
    return 'Logging in...' if @loginForm.saving()
    return 'Suit up!'

  loginFormTitle: ->
    return @loginForm.error() or 'Login'

  showSignup: ->
    loginEl = jQuery('#pool-join-login-btn')
    loginEl.removeClass('inactive')
    signupEl = jQuery('#pool-join-signup-btn')
    signupEl.addClass('inactive')
    @loginFormVisible(false)
    @signupFormVisible(true)

  signupFormTitle: ->
    return @signupForm.error() or 'Signup'

  submitSignupText: ->
    return 'Creating account...' if @signupForm.saving()
    return 'Dive In!'

  onAuthenticate: ->
    @authCallback()

class PI.pages.CampaignJoinContributeScreen extends PI.pages.Page

  constructor: (config) ->
    @campaign = config.campaign
    @form = new PI.forms.CampaignJoinForm({
      campaign: @campaign,
      submitPayment: config.submitPayment
    })

    @form.saved.add(config.paymentSuccess, this)
    @form.failed.add(config.paymentFailure, this)

    @formTitle = ko.computed(@formTitle, this)
    @submitText = ko.computed(@submitText, this)

    @afterFees = ko.observable(@form.amount())
    @afterFees = @afterFees.extend(money: precision: 2)
    @totalAfterFees = ko.computed(@totalAfterFees, this)
    @totalAfterFees.extend({ throttle: 500 });

  formTitle: ->
    return @campaign.name()

  submitText: ->
    return 'Submitting Payment...' if @form.saving()
    return 'Submit Payment!'

  totalAfterFees: ->
    @updateFeeAmount(charge: final: 0) if @form.amount.error() or @form.amount() == '0'
    return if @form.amount.error() or @form.amount() == '0'
    endpoint = "/pool/#{@campaign.id()}/fees?amount=#{@form.amount()}"
    jQuery.ajax({
      context: this,
      mimeType: 'application/json',
      contentType: 'application/json',
      success: @updateFeeAmount,
      type: 'GET'
      url: endpoint
    })

  updateFeeAmount: (value, message, xhr) ->
    @afterFees(value.charge.final)



class PI.forms.CampaignJoinForm extends PI.forms.Form

  init: (config) ->
    @campaign = config.campaign
    @endpoint = "/pool/#{@campaign.id()}/join"
    @submitCallback = config.submitPayment
    now = new Date()

    @field
      name: 'fullName',
      label: 'Full Name',
      validators: [
        new PI.forms.Required(),
      ]

    @field
      name: 'amount',
      label: 'amount',
      value: @campaign.suggestedContribution() or '0'
      validators: [
        new PI.forms.Required(),
        new PI.forms.PositiveInteger({
          max: 942718
        })
      ]

    @field
      name: 'cc',
      label: 'Credit Card Number',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.ValidateCC()
      ]

    @field
      name: 'ccv',
      label: 'CCV',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.ValidateCCV()
      ]

    @field
      name: 'expMonth',
      label: 'Expiration Month',
      filter: true,
      value: now.getMonth()+1,
      validators: [
        new PI.forms.Required(),
      ]

    @field
      name: 'expYear',
      label: 'Expiration Year',
      filter: true,
      value: now.getFullYear(),
      validators: [
        new PI.forms.Required(),
      ]

    @field
      name: 'expiry',
      label: 'Expiration Date',
      filter: true,
      value: ko.computed(@expiryDate, this),
      validators: [
        new PI.forms.Required(),
        new PI.forms.ValidateExpiry(),
      ]

    @field
      name: 'stripeToken'

    @field
      name: 'stripeCreated'

    @field
      name: 'currency',
      label: 'currency',
      value: 'USD'

    @years = (m for m in [now.getFullYear()..now.getFullYear() + 12])
    @months = (m for m in [1..12])

    @expiryLabel = ko.computed(@expiryLabel, this)

  expiryDate: ->
    return "#{@expMonth()}/#{@expYear()}"

  expiryLabel: ->
    return 'Expiration' unless @expiry.error()
    return 'Invalid Expiration'

  submit: =>
    @validate().done (valid) =>
      return unless valid
      @submitted.dispatch(this)
      @submitCallback(this, @addStripe)
    return this

  addStripe: (data) =>
    @stripeToken(data.id)
    @stripeCreated(data.created)

    @save() if @autosave


class PI.pages.CampaignJoinProcessingScreen extends PI.pages.Page

  constructor: (config) ->
    @opts =
      lines: 10,
      length: 10,
      width: 2,
      radius: 10,
      corners: 1,
      rotate: 0,
      color: "#000",
      speed: 1,
      trail: 40,
      shadow: true,
      hwaccel: false,
      className: 'processingSpinner',
      zIndex: 2e9,
      top: 'auto',
      left: 'auto'

  startSpinner: ->
    target = jQuery('#pool-join-processing .spinner')
    @spinner = new Spinner(@opts).spin(target[0])

  stopSpinner: =>
    @spinner.stop()


class PI.pages.CampaignJoinCompleteScreen extends PI.pages.Page

  constructor: (config) ->
    @payment = new PI.campaign.CampaignPayment(config.payment)

  update: (data) =>
    @payment.update(data)


class PI.pages.CampaignJoinPage extends PI.pages.Page

  constructor: (config) ->
    config ?= {}
    @title = config.title or "Join Pool"

    @campaign = new PI.campaign.Campaign(config.campaign)

    @authScreen = new PI.pages.CampaignJoinAuthenticateScreen({
      login: config.login or undefined,
      authSuccessCallback: @userAuthed
    })
    showAuthScreen = config.requireLogin
    @authScreenVisible = ko.observable(showAuthScreen)

    @contributeScreen = new PI.pages.CampaignJoinContributeScreen({
      campaign: @campaign,
      submitPayment: @submitPayment,
      paymentSuccess: @paymentSuccess,
      paymentFailure: @paymentFailure

    })
    @contributeScreenVisible = ko.observable(not showAuthScreen)

    @processingScreen = new PI.pages.CampaignJoinProcessingScreen({ })
    @processingScreenVisible = ko.observable(false)

    @completeScreen = new PI.pages.CampaignJoinCompleteScreen({
      payment: config.successResponse
    })
    @completeScreenVisible = ko.observable(false)

    Stripe.setPublishableKey(config.publishable_key)

  userAuthed: =>
    @authScreenVisible(false)
    @contributeScreenVisible(true)

  submitPayment: (data, callback) =>
    @contributeScreenVisible(false)
    @processingScreenVisible(true)
    @processingScreen.startSpinner()
    @saveCallback = callback
    data =
      number: data.cc(),
      cvc: data.ccv(),
      exp_month: data.expMonth(),
      exp_year: data.expYear(),
      name: data.fullName()
    Stripe.createToken(data, @stripeResponseHandler)

  stripeResponseHandler: (status, response) =>
    @stripeHandleError(response) if response.error
    @saveCallback(response)

  stripeHandleError: (response) =>
    @processingScreen.stopSpinner()
    @processingScreenVisible(false)
    @contributeScreenVisible(true)

  paymentSuccess: (form, xhr) =>
    data = JSON.parse(xhr.responseText)
    @completeScreen.update(data)
    @processingScreen.stopSpinner()
    @processingScreenVisible(false)
    @completeScreenVisible(true)

  paymentFailure: (form, xhr) =>
    @processingScreen.stopSpinner()
    @processingScreenVisible(false)
    @contributeScreenVisible(true)
