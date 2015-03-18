describe 'RootView', ->
  
  describe '.title()', ->
    it 'should return a string which will go into the page\'s title tag onInsert', ->
      oldTitle = $('title').text()
      View = FrimFram.RootView.extend({
        title: -> 'Home Page'
      })
      view = new View()
      view.onInsert()
      expect($('title').text()).toBe('Home Page')
      $('title').text(oldTitle)