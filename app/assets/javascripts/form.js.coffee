# Load up the form if it is there

$(->
  timeOutId = null
  showSyncError = true

  getSignups = ->
    signups = JSON.parse(localStorage.getItem('signups'))
    signups = {} unless signups != null && typeof signups == 'object'
    return signups

  setSignups = (signups) ->
    localStorage.setItem('signups', JSON.stringify(signups))

  sync = ->
    return unless window.navigator.onLine

    try
      signups = getSignups()
      activeSignups = []
      for own key, value of signups
        if not value.isLogged
          activeSignups.push
            id: key
            value: value

      if activeSignups.length > 0
        $.ajax(
          type: "POST"
          url: "/signups/sync"
          data: { data: JSON.stringify((signup.value for signup in activeSignups)) }
        ).always((response) ->
          try
            data = JSON.parse(response.responseText)
          catch e
            # do nothing
          if data? and 'success' of data and data.success
            cachedSignups = getSignups()
            for signup in activeSignups
              cachedSignups[signup.id].isLogged = true
            setSignups(cachedSignups)
          else if showSyncError
            alert "Error syncing with server"
            showSyncError = false
        )
    catch error
      alert "Error syncing: #{error}"
  
  validator = $(".signup-form").validate(
    highlight: (elem) ->
      $(elem).closest('.control-group').removeClass('success').addClass('error')
    success: (elem) ->
      $(elem).text('OK!').addClass('valid')
             .closest('.control-group').removeClass('error').addClass('success')
    submitHandler: (form) ->
      try
        email = $("#email-text").val()
        name = $("#name-text").val()
        $("#email-text").val("")
        $("#name-text").val("")
        $("#email-placeholder").text(email)
        # stash it away
        signups = getSignups()
        signups[new Date().getTime()] = {
          name
          email
          isLogged: false
        }
        setSignups(signups)
        # set up alerts
        $("#success-alert").animate({
          opacity: 1
        })
        if timeOutId
          clearTimeout(timeOutId)
        timeOutId = setTimeout(->
          $("#success-alert").animate({
            opacity: 0
          })
        , 4000)

        $("#name-text").focus()
        sync()
        validator.resetForm()
        $('.control-group').removeClass('success')
      catch error
        alert "Error signing up: #{error}"
  )
  $("#name-text").focus()
  sync()
  setInterval(sync, 30000) # Attempt to sync every 30 seconds
  $(window).bind("online", sync)
)

# fix ajax stuff
jQuery(document).ajaxSend (event, request, settings) ->
    request.setRequestHeader("Accept", "text/javascript")
    request.setRequestHeader("X-Requested-With", "XMLHttpRequest")
    request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    return if (settings.type.toUpperCase() == 'GET' || typeof(AUTH_TOKEN) == "undefined")
    # settings.data is a serialized string like "foo=bar&baz=boink" (or null)
    settings.data = settings.data || ""
    if typeof(AUTH_TOKEN) != "undefined"
      settings.data += (if settings.data then "&" else "") + "authenticity_token=" + encodeURIComponent(AUTH_TOKEN)
