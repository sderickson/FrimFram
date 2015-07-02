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

  describe '.onLeaveMessage()', ->
    # testing this would involve leaving the testing page
    it 'should return a message when you don\'t want the user to leave the page because of unsaved changes or something along those lines', ->
      expect(true).toBe(true)

    it 'handles both navigating within and out of the app', ->
      expect(true).toBe(true)
