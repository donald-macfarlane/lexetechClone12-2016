jquery = require './jquery'

send (method, url, body) =
  jquery.ajax! {
    url = url
    type = method
    contentType = 'application/json; charset=UTF-8'
    data = JSON.stringify(body)
  }

module.exports = {
  get(url) = send 'GET' (url)!
  delete(url) = send 'DELETE' (url)!

  post(url, body) = send 'POST' (url, body)!
  put(url, body) = send 'PUT' (url, body)!

  onError(fn) =
    jquery(document).ajaxError(fn)
}
