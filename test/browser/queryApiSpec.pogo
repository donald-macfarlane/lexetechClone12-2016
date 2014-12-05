queryApi = require '../../browser/queryApi.pogo'
window.$ = window.jQuery = require 'jquery'
require '../../bower_components/jquery-mockjax/jquery.mockjax.js'

describe 'query api'
  before
    $.mockjaxSettings.logging = false

  it 'inserts query()s for each response'
    $.mockjax {
      url = '/queries/first'

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

    console.log($.get '/queries/first'!)
