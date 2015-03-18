describe 'ModalView', ->

  it 'proxies Bootstrap Events as Bootstrap Events'

  describe '.show()', ->
    it 'closes currently visible modal'
    
    it 'sets ModalView.visibleModal to itself'
    
    it 'puts the view\'s element into the body tag'
    
  describe '.hide()', ->
    it 'clears ModalView.visibleModal'
    
    it 'destroys itself at the end of the hiding process'
    
    it 'hides itself fast if the first argument is true'
    