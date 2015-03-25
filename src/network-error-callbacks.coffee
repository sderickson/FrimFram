
#- Error handling
FrimFram.onModelError = (model, jqxhr) -> FrimFram.onAjaxError(jqxhr)

FrimFram.onAjaxError = (jqxhr) ->
  r = jqxhr.responseJSON
  console.log r or jqxhr.responseText
  r ?= {}
  s = "Response error #{r.error} (#{r.statusCode}): #{r.message}"
  alert = $(FrimFram.runtimeErrorTemplate({errorMessage: s}))
  $('body').append(alert)
  alert.addClass('in')
  alert.alert()
  close = -> alert.alert('close')

FrimFram.runtimeErrorTemplate = _.template("""
  <div class="runtime-error-alert alert alert-danger fade">
    <button class="close" type="button" data-dismiss="alert">
      <span aria-hidden="true">&times;</span>
    </button>
    <strong class="spr">Runtime Error:</strong>
    <span><%= errorMessage %></span>
    <br/>
    <span class="pull-right text-muted">See console for more info.</span>
  </div>
""")

