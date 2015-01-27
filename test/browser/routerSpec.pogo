createRouter = require './router'
expect = require 'chai'.expect
http = require '../../browser/http'

describe 'router'
  it 'can get'
    router = createRouter()

    router.get '/path/:name/:id' @(req)
      {
        body = { route = 'one', params = req.params }
      }

    expect(http.get! '/path/1/2?c=3').to.eql {
      route = 'one'
      params = {
        name = '1'
        id = '2'
        c = '3'
      }
    }

  it 'can post'
    router = createRouter()

    router.post '/one/:name/:id' @(req)
      {
        body = { route = 'one', body = req.body, params = req.params }
      }

    response = http.post! '/one/1/2?c=3' { data = 'blah' }
    expect(response).to.eql {
      route = 'one'
      body = {
        data = 'blah'
      }
      params = {
        name = "1"
        id = "2"
        c = "3"
      }
    }
