describe 'BaseView', ->
  it 'listens to shortcuts upon construction'
  
  
  describe '.render()', ->
    it 'destroys and resets subviews'
    
    it 'inserts the template value into $el'
    
    it 'it calls afterRender at the end'
    
    
  describe '.renderSelectors()', ->
    it 'rerenders selectors passed in as arguments'
    
    
  describe '.getContext()', ->
    it 'picks passed in properties from the view instance'
    
    it 'includes pathname'
    
    
  describe '@setGlobals()', ->
    it 'specifies what globals all View contexts will have'
    
    
  describe '.listenToShortcuts()', ->
    it 'sets up shortcuts listed in the shortcuts property'
    
    it 'recursively calls subviews when the first argument is true'
    
    
  describe '.stopListeningToShortcuts()', ->
    it 'removes shortcuts set up for the view'
      
    it 'recursively calls subviews when the first argument is true'
    
  
  describe '.insertSubview()', ->
    it 'takes a view as its first argument and inserts it based on the view\'s id property'
    
    it 'calls the subview\'s render and afterInsert methods'
    
  
  describe '.registerSubview()', ->
    it 'adds the given view to the subviews property'
    
    
  describe '.removeSubView()', ->
    it 'removes and destroys a given view'
    
    
  describe '@getQueryVariable() and .getQueryVariable()', ->
    it 'parses a given parameter out of the query string'
    
  
  describe '@destroy()', ->
    it 'calls Backbone.View.remove'
    
    it 'stops listening to shortcuts'
    
    it 'destroys all subviews'

    it 'clears all properties from the object, except for "destroyed" and "destroy"'