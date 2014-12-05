window.$ = window.jQuery = require 'jquery'
expect = require 'chai'.expect
queryApi = require '../../browser/queryApi.pogo'
require '../../bower_components/jquery-mockjax/jquery.mockjax.js'

describe 'query api'
  before
    $.mockjaxSettings.logging = false

  it 'inserts query()s for each response'
    $.mockjax {
      url = '/queries/first/graph'

      responseText = {
        query = {
          text = 'query 1'

          responses = [
            {
              text = 'response 1'
              query = {
                text = 'query 2'

                responses = [
                  {
                    text = 'response 1'
                  }
                ]
              }
            }
          ]
        }
      }
    }

    graph = queryApi.firstQuery()!

    expect(graph.query.text).to.equal 'query 1'
    expect(graph.query.responses.0.text).to.equal 'response 1'
    expect(graph.query.responses.0.query()!.text).to.equal 'query 2'
    expect(graph.query.responses.0.query()!.responses.0.text).to.equal 'response 1'
