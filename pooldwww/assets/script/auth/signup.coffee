class PI.UserSignup extends PI.Page

  constructor: ->
    @email = ko.observable()
    @username = ko.observable()
    @password = ko.observable()
    @passwordConfirm = ko.observable()
    @isClean = ko.observable(true)


   submit: ->
     return if not @isClean()
     data = @dumpForm()
     jQuery.post('/signup', data, undefined, 'json')
           .done(@onSuccess)
           .fail(@onError)

   dumpForm: ->
     return {
       email: @email(),
       username: @username(),
       password: @password(),
       password_confirm: @passwordConfirm()
     }

   onSuccess: (data) ->

   onError: ->
