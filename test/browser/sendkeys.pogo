dispatchEvent(el, type, char) =
  event = document.createEvent('Events')
  event.initEvent(type, true, false)
  event.charCode = char
  el.dispatchEvent(event)

sendkey(el, char) =
  dispatchEvent(el, 'keydown', char)
  dispatchEvent(el, 'keyup', char)
  dispatchEvent(el, 'keypress', char)

module.exports(el, text) =
  for(n = 0, n < text.length, ++n)
    char = text.(n)
    el.value = text.substring(0, n + 1)
    sendkey(el, char)

  dispatchEvent(el, 'input')

module.exports.html(el, html) =
  el.innerHTML = html
  dispatchEvent(el, 'input')
