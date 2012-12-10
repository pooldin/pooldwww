PI.models = {}

campaign = new PI.Schema()
campaign.mapMoment('end')

class PI.user.Campaign extends PI.Model

  @schema: campaign

  constructor: (data) ->
    super(data)
    @pathRoot = data.profileRoot or '/pool'
    @link = "#{window.location.protocol}//#{window.location.host}#{@pathRoot}/#{@id()}"
    @year = ko.observable()
    @month = ko.observable()
    @day = ko.observable()
    @setDate()

  activeString: ->
    now = new Date()
    if not @end() or now < @end()
      return 'Active'
    return 'Completed'

  endString: ->
    now = new Date()
    return if not @end()
    return if now > @end()
    return "Ends #{@month()}.#{@day()}.#{@year()}"

  setDate: ->
    return unless @end
    @year(@end().year())
    @month(@end().month() + 1)
    @day(@end().date())


class PI.user.ProfileForm extends PI.forms.Form

  init: (config) ->
    @field
      name: 'username'
      value: config.username,

    @field
      name: 'about',
      value: config.about or '',
      validators: [
        new PI.forms.MaximumLength({'length': 500})
      ]

    @endpoint = "/profile/#{@username()}/update"


class PI.pages.ProfileViewPage extends PI.pages.Page

  constructor: (config) ->
    config ?= {}

    @form = new PI.user.ProfileForm(config)
    @form.saved.add(@onSaved, this)
    @form.failed.add(@onFailed, this)

    @error = ko.observable(false)
    @success = ko.observable(false)

    @isEditing = ko.observable(false)
    @displayTextPlaceholder = ko.computed(@displayTextPlaceholder, this)

    @title = ko.computed(@title, this)

    @campaigns = ko.observableArray([])
    for campaign in config.campaigns
      c = new PI.user.Campaign(campaign)
      @campaigns.push(c)

    el = $('.change-gravatar .icon-question-sign')
    options =
      animate: true,
      html: false,
      placement: 'bottom',
      trigger: 'click',
      title: 'Gravatar is your Avatar',
      content: 'To help ease the pain of establishing a consistent web persona, we use Gravatar to provide user avatars. Head on over to www.gravatar.com or click the provided link to set yours up today!'
    el.popover(options)

  title: ->
    return 'Updated!' if @success() is true and @form.about()
    return 'Antisocial Badge Earned!' if @success() is true and not @form.about()
    return 'Update Failed!' if @error() is true
    return 'About'

  onSaved: ->
    @success(true)
    setTimeout((() => @success(undefined)), 5000)

  onFailed: ->
    @error(true)
    setTimeout((() => @error(undefined)), 5000)

  toggleEdit: ->
    @isEditing(not @isEditing())
    jQuery('.about-text').focus() if @isEditing

  saveEdit: ->
    text = jQuery.trim(jQuery('.about-text').text())
    changed = @form.about() != text
    if changed
      @form.about(text)
      @form.submit()
    jQuery('.about-text').text(text)
    @toggleEdit()

  cancelEdit: ->
    text = @form.about()
    if not text
      text = ''
    jQuery('.about-text').text(text)
    @toggleEdit()

  displayTextPlaceholder: =>
    return not @isEditing() and not @form.about()
