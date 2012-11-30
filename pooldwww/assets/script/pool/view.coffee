PI.campaign = PI.campaign or {}


class PI.forms.EmailFieldValidator extends PI.forms.Validator

  constructor: (config) ->
    super(config)
    @emailValidator = new PI.forms.Email(config)

  isValid: (value) ->
    emails = value.split(',')
    for email in emails
      email = email.trim()
      if not @emailValidator.isValid(email)
        return false
    return true


class PI.forms.CampaignEmailInviteForm extends PI.forms.Form

  init: (config) ->
    config ?= {}

    @field
      name: 'toField',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.EmailFieldValidator()
      ]

    @field
      name: 'to',
      validators: [
        new PI.forms.Required()
      ]

    @field
      name: 'message',
      value: '',
      validators: [
        new PI.forms.Required()
      ]

    @id = config.id
    @pathRoot = config.pathRoot or '/pool'
    @endpoint = "#{@pathRoot}/#{@id}/send/invite"


class PI.forms.CampaignEmailUpdateForm extends PI.forms.Form

  init: (config) ->
    config ?= {}

    @field
      name: 'toField',
      filter: true,
      validators: [
        new PI.forms.Required(),
        new PI.forms.EmailFieldValidator()
      ]

    @field
      name: 'to',
      validators: [
        new PI.forms.Required()
      ]

    @field
      name: 'message',
      value: '',
      validators: [
        new PI.forms.Required()
      ]

    @field
      name: 'update_to',
      value: '',
      validators: [
      ]

    @id = config.id
    @pathRoot = config.pathRoot or '/pool'
    @endpoint = "#{@pathRoot}/#{@id}/send/update"


class PI.pages.CampaignPromoteScreen extends PI.pages.Page

  constructor: (config) ->
    config ?= {}
    @id = config.id
    @pathRoot = config.pathRoot or '/pool'
    @link = "#{window.location.protocol}//#{window.location.host}#{@pathRoot}/#{@id}"


class PI.pages.CampaignInviteScreen extends PI.pages.Page

  constructor: (config) ->
    config ?= {}
    @id = config.id
    @form = new PI.forms.CampaignEmailInviteForm(config)

    @form.saved.add(@onInviteSaved, this)
    @form.failed.add(@onInviteFailed, this)

  submitInvites: ->
    trimmedEmails = []
    emails = @form.toField()
    for email in emails.split(',')
      trimmedEmails.push(email.trim())
    @form.to(trimmedEmails.join(','))

    @form.submit()

  cancelInvites: ->
    @form.empty()
    # Hack to get back since we dont' have access to the parent object here...
    bar = $('.promote-bar:visible')
    bar.click()

  onInviteSaved: ->
    # Need to add messaging
    @cancelInvites()

  onInviteFailed: ->
    # Need to add messaging


class PI.pages.CampaignUpdateScreen extends PI.pages.Page

  constructor: (config) ->
    config ?= {}
    @id = config.id
    @form = new PI.forms.CampaignEmailUpdateForm(config)

    @form.saved.add(@onUpdateSaved, this)
    @form.failed.add(@onUpdateFailed, this)

    @recipientsEditable = ko.observable(false)
    @participants = config.community

    @updateTo = ko.observable('community')
    @updateToUpdated = ko.computed(@_updatedToUpdated)
    @_updatedToUpdated()

  _updatedToUpdated: () =>
    value = @updateTo()
    emails = []
    addRecipient = (member) ->
      emails.push(member.email())
      member.sendUpdate(true)
    removeRecipient = (member) ->
      member.sendUpdate(false)

    if value == 'community'
      @recipientsEditable(false)
      filter = (member) ->
        #emails.push(member.email()) unless member.isOrganizer()
        addRecipient(member) unless member.isOrganizer()
        removeRecipient(member) if member.isOrganizer()
    if value == 'participants'
      @recipientsEditable(false)
      filter = (member) ->
        #emails.push(member.email()) unless member.invitee() or member.isOrganizer()
        addRecipient(member) unless member.invitee() or member.isOrganizer()
        removeRecipient(member) if member.invitee() or member.isOrganizer()
    if value == 'invitees'
      @recipientsEditable(false)
      filter = (member) ->
        #emails.push(member.email()) if member.invitee()
        addRecipient(member) if member.invitee()
        removeRecipient(member) unless member.invitee()

    @participants().forEach(filter)
    @form.toField(emails.join(', '))

  submitUpdate: ->
    trimmedEmails = []
    emails = @form.toField()
    for email in emails.split(',')
      trimmedEmails.push(email.trim())
    @form.to(trimmedEmails.join(','))

    @form.submit()


  cancelUpdate: ->
    @form.empty()
    # Hack to get back since we dont' have access to the parent object here...
    bar = $('.promote-bar:visible')
    bar.click()

  onUpdateSaved: ->
    # Need to add messaging
    @cancelUpdate()

  onUpdateFailed: ->
    # Need to add messaging


class PI.forms.CampaignUpdateForm extends PI.forms.Form

  init: (config) ->
    @field
      name: 'text',
      value: '',
      validators: [
        new PI.forms.Required(),
        new PI.forms.MaximumLength({'length': 500})
      ]
    @field
      name: 'timestamp',
      validators: [
        new PI.forms.Required(),
      ]

    @pathRoot = config.pathRoot or '/pool'
    @id = config.id
    @endpoint = "#{@pathRoot}/#{@id}/update"

  submit: ->
    now = new Date()
    @timestamp(now.getTime())
    super()


participant = new PI.Schema()
participant.mapMoment('joinedDate')

class PI.campaign.Participant extends PI.Model

  @schema: participant

  constructor: (data) ->
    super(data)
    @pathRoot = data.profileRoot or '/profile'
    @link = "#{window.location.protocol}//#{window.location.host}#{@pathRoot}/#{@username()}"
    @dollarAmount = ko.computed(@formatDollarAmount)
    @sendUpdate = ko.observable(false)

    @year = ko.observable()
    @month = ko.observable()
    @day = ko.observable()
    @setDate()

  formattedJoinDate: ->
    return "#{@month()}.#{@day()}.#{@year()}"

  setDate: ->
    return unless @joinedDate
    @year(@joinedDate().year())
    @month(@joinedDate().month() + 1)
    @day(@joinedDate().date())

  formatDollarAmount: =>
    return 0 if @invitee()
    amount = @amount.extend(money: precision: 2)
    return amount()

campaignUpdate = new PI.Schema()
campaignUpdate.mapMoment('timestamp')

class PI.campaign.CampaignUpdate extends PI.Model
  @schema: campaignUpdate

  constructor: (data) ->
    super(data)

    @year = ko.observable()
    @month = ko.observable()
    @day = ko.observable()
    @setDate()
    @dateString = ko.computed(@computeDateString)

  computeDateString: =>
    now = new Date()
    return "#{@month()}.#{@day()}.#{@year()}"

  setDate: ->
    return unless @timestamp
    @year(@timestamp().year())
    @month(@timestamp().month() + 1)
    @day(@timestamp().date())


campaign = new PI.Schema()
campaign.mapMoment('end')

class PI.campaign.Campaign extends PI.Model

  constructor: (data) ->
    updates = data.updates or []
    delete data.updates if updates

    participants = data.participants or []
    delete data.participants if participants

    super(data)

    @participants = ko.observableArray()
    for participant in participants
      @participants.push(new PI.campaign.Participant(participant))
    @participantCount = ko.computed(@countParticipants)

    @updates = ko.observableArray()
    for update in updates
      @updates.push(new PI.campaign.CampaignUpdate(update))

    @amount = @amount.extend(money: precision: 2)
    @_contributionAmount = ko.observable(0).extend(money: precision: 2)
    @contributionAmount = ko.computed(@calculateContributionAmount)

    @countParticipants = ko.computed(@countParticipants, this)

    @days = ko.computed(@calculateDaysRemaining)
    @hours = ko.computed(@calculateHoursRemaining)
    @minutes = ko.computed(@calculateMinutesRemaining)

  addUpdate: (data) ->
    update = new PI.campaign.CampaignUpdate(data)
    @updates.push(update)

  countParticipants: =>
    count = 0
    sum = (p) ->
      return if p.invitee()
      count += 1
    @participants().forEach(sum)
    return count

  calculateContributionAmount: =>
    total = 0
    sum = (p) ->
      return if p.invitee()
      total += parseInt(p.amount()) or 0
    @participants().forEach(sum)
    @_contributionAmount(total)
    return @_contributionAmount()

  calculateDaysRemaining: =>
    now = new Date()
    left = parseInt((@end() - now) / (3600000 * 24))
    return left unless left < 0
    return 0

  calculateHoursRemaining: =>
    now = new Date()
    left = parseInt(((@end() - now) - @calculateDaysRemaining()*(3600000 * 24)) / 3600000)
    return left unless left < 0
    return 0

  calculateMinutesRemaining: =>
    now = new Date()
    left = parseInt(((@end() - now) - @calculateDaysRemaining()*(3600000 * 24) - (@calculateHoursRemaining()*3600000)) / 60000)
    return left unless left < 0
    return 0


class PI.pages.PoolViewPage extends PI.pages.Page

  constructor: (config) ->
    config ?= {}
    @title = config.title or "Pool"

    campaignConfig =
      id: config.campaignId,
      participants: config.participants,
      description: config.description,
      updates: config.updates,
      amount: config.amount,
      end: config.endTimestamp
    @campaign = new PI.campaign.Campaign(campaignConfig)

    @promoteScreen = new PI.pages.CampaignPromoteScreen(id: config.campaignId)
    @inviteScreen = new PI.pages.CampaignInviteScreen(id: config.campaignId)
    @updateScreen = new PI.pages.CampaignUpdateScreen(id: config.campaignId, community: @campaign.participants)

    @viewScreenVisibile = ko.observable(true)
    @promoteScreenVisible = ko.observable(false)
    @inviteScreenVisibile = ko.observable(false)
    @updateScreenVisibile = ko.observable(false)

    @tabbedContent = new PI.pages.TabbedContent(config.tabs or {})

    stickyBarConfig =
      selector: '.promote-bar:visible',
      minYPosition: 40
      yOffset: 5
    @stickyPromoteBar = new PI.pages.StickyBar(stickyBarConfig)

    @updatingDescription = false
    @updateForm = new PI.forms.CampaignUpdateForm({id: config.campaignId})
    @updateForm.saved.add(@onUpdateSaved, this)
    @updateForm.failed.add(@onUpdateFailed, this)

    @updateEL = jQuery('<form><textarea class="pool-description-update" data-bind="value: updateForm.text, valueUpdate: \'afterkeydown\'"></textarea><a href="#" class="btn pull-right" data-bind="click: submitDescriptionUdate">Submit</a></form><div class="clearfix"></div>')
    @clickEL = undefined

  tabs: (tab) ->
    return @tabbedContent.tab(tab)

  onUpdateSaved: (form, xhr) ->
    @removeDescriptionUpdate()
    data = JSON.parse(xhr.responseText)
    newUpdate = data['updates'].pop()
    @campaign.addUpdate(newUpdate)

  onUpdateFailed: ->

  removeDescriptionUpdate: =>
    parent = jQuery('#pool-view-description')

    form = parent.children('form')
    form.css({display: 'none'})

    @updateForm.empty()

    @clickEL.addClass('clickable')
    @clickEL = undefined

    @updatingDescription = false

  addDescriptionUpdate: =>
    return if @updatingDescription

    @updatingDescription = true
    parent = jQuery('#pool-view-description')
    @clickEL = parent.children('.clickable')
    @clickEL.removeClass('clickable')

    #parent.append(@updateEL)
    form = parent.children('form')
    form.css({display: ''})

  submitDescriptionUdate: ->
    parent = jQuery('#pool-view-description')
    @updateForm.submit()

  viewPromoteTransition: ->
    @promoteScreenVisible(not @promoteScreenVisible())
    @viewScreenVisibile(not @viewScreenVisibile())
    if @promoteScreenVisible()
      jQuery('#pool-view-promote').show()
      jQuery('#pool-view-overview').hide()
    if not @promoteScreenVisible()
      jQuery('#pool-view-promote').hide()
      jQuery('#pool-view-overview').show()

  promoteInviteTransition: ->
    @promoteScreenVisible(not @promoteScreenVisible())
    @inviteScreenVisibile(not @inviteScreenVisibile())
    if @promoteScreenVisible()
      jQuery('#pool-view-promote').show()
      jQuery('#pool-view-invite').hide()
    else
      jQuery('#pool-view-promote').hide()
      jQuery('#pool-view-invite').show()

  promoteUpdateTransition: ->
    @promoteScreenVisible(not @promoteScreenVisible())
    @updateScreenVisibile(not @updateScreenVisibile())
    if @promoteScreenVisible()
      jQuery('#pool-view-promote').show()
      jQuery('#pool-view-update').hide()
    else
      jQuery('#pool-view-promote').hide()
      jQuery('#pool-view-update').show()
