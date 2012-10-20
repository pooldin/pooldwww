class PI.pages.Settings extends PI.pages.Page

  constructor: (config) ->
    @config = config

    @form = config.form
    @form?.saved.add(@onSaved, this)

  onSaved: ->
    console.log('saved')
