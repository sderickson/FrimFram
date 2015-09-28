SampleModal = require('views/SampleModal')

class HomeView extends FrimFram.RootView
  events:
    'click #open-sample-modal-btn': 'onClickOpenSampleModalButton'

  template: require 'templates/home-view'

  onClickOpenSampleModalButton: ->
    modal = new SampleModal()
    modal.show()

module.exports = HomeView
