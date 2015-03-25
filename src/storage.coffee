FrimFram.storage = {
  prefix: '-storage-'
  
  load: (key) ->
    s = localStorage.getItem(@prefix+key)
    unless s
      return null
    try
      value = JSON.parse(s)
      return value
    catch SyntaxError
      console.warn('error loading from storage', key)
      return null
  
  save: (key, value) ->
    localStorage.setItem(@prefix+key, JSON.stringify(value))
  
  remove: (key) ->
    localStorage.removeItem(@prefix+key)
    
  clear: ->
    for key of localStorage
      if key.indexOf(@prefix) is 0
        localStorage.removeItem(key)
}
