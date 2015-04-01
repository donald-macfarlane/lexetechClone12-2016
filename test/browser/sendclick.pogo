$ = require '../../browser/jquery'

module.exports(el) =
  event = new (MouseEvent 'click' {
    view = window
    bubbles = true
    cancelable = true
  })
  el.dispatchEvent(event)
