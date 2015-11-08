
#- Error handling
FrimFram.onNetworkError = ->
  jqxhr = _.find arguments, (arg) -> arg.promise? and arg.getResponseHeader? # duck typing

  r = jqxhr?.responseJSON
  if jqxhr?.status is 0
    s = 'Network failure'
  else if arguments[2]?.textStatus is 'parsererror'
    s = 'Backbone parser error'
  else
    s = r?.message or r?.error or 'Unknown error'

  if r
    console.error 'Response JSON:', JSON.stringify(r, null, '\t')
  else
    console.error 'Error arguments:', arguments

  alert = $(FrimFram.runtimeErrorTemplate({errorMessage: s}))
  $('body').append(alert)
  alert.addClass('in')
  alert.alert()


FrimFram.runtimeErrorTemplate = _.template("""
  <div class="runtime-error-alert alert alert-danger fade">
    <button class="close" type="button" data-dismiss="alert">
      <span aria-hidden="true">&times;</span>
    </button>
    <span><%= errorMessage %></span>
  </div>
""")

