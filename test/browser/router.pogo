$ = window.$ = window.jQuery = require 'jquery'
require '../../bower_components/jquery-mockjax/jquery.mockjax.js'

$.mockjaxSettings.responseTime = 0
$.mockjaxSettings.logging = false

route(r) =
  new (RegExp(r.replace(r/:[a-z0-0]+/ig, '([^/?]*)') + '(\?(.*))?'))

params(pattern, url) =
  re = r/:([a-z0-9]+)/ig
  m = nil
  vars = []

  matches() =
    m := re.exec(pattern)

    if (m)
      vars.push(m.1)
      matches()

  matches()

  routeMatch = route(pattern).exec(url)

  hash = {}

  for(n = 0, n < vars.length, ++n)
    hash.(vars.(n)) = routeMatch.(n + 1)

  queryString = routeMatch.(vars.length + 2)
  if (queryString)
    queryString.split r/&/.forEach @(param)
      paramNameValue = param.split r/=/
      name = paramNameValue.0
      value = decodeURIComponent(paramNameValue.1)

      hash.(name) = value

  hash

routerPrototype = {}

['get', 'delete', 'head', 'post', 'put', 'patch'].forEach @(method)
  routerPrototype.(method) (url, fn) =
    $.mockjax @(settings)
      if (settings.url.match(route(url)) @and settings.type.toLowerCase() == method)
        {
          response(settings) =
            requestBody =
              if (settings.data != nil @and (settings.dataType == 'json' @or settings.contentType.match(r/^application\/json\b/)))
                JSON.parse(settings.data)
              else
                settings.data

            response = fn {
              headers = settings.headers @or []
              body = requestBody
              method = settings.type
              url = settings.url
              params = params(url, settings.url)
            } @or {}

            self.headers = response.headers @or {}
            self.status = response.statusCode @or 200
            self.responseText = response.body
        }

router = prototype (routerPrototype)

module.exports() =
  $.mockjax.clear()
  router()
