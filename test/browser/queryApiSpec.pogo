window.$ = window.jQuery = require 'jquery'
expect = require 'chai'.expect
queryApi = require '../../browser/queryApi.pogo'
require '../../bower_components/jquery-mockjax/jquery.mockjax.js'

describe 'query api'
  before
    $.mockjaxSettings.logging = false

  beforeEach
    $.mockjax.clear()

  it 'inserts query()s for each response'
    $.mockjax {
      url = '/queries/first/graph?depth=4'

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

  it 'loads next query when it reaches a partial'
    $.mockjax {
      url = '/queries/first/graph?depth=4'

      responseText = {
        query = {
          text = 'query 1'

          responses = [
            {
              text = 'response 1'
              query = {
                text = 'query 2'
                partial = true
                hrefTemplate = '/queries/2'

                responses = [
                  {
                    text = 'response 1'
                  }
                ]
              }
            }
            {
              text = 'response 2'
              query = {
                text = 'query 2'
                partial = true
                hrefTemplate = '/queries/2'

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

    calls = 0
    $.mockjax {
      url = '/queries/2'

      response() =
        ++calls

        self.responseText = {
          query = {
            text = 'query 2'

            responses = [
              {
                text = 'response 1'
                query = {
                  text = 'query 3'

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

    query = graph.query
    expect(query.text).to.equal 'query 1'
    expect(query.responses.0.text).to.equal 'response 1'

    query := query.responses.0.query()!
    expect(query.text).to.equal 'query 2'
    expect(query.responses.0.text).to.equal 'response 1'

    query := query.responses.0.query()!
    expect(query.text).to.equal 'query 3'
    expect(query.responses.0.text).to.equal 'response 1'

    query := graph.query
    query := query.responses.1.query()!
    expect(query.text).to.equal 'query 2'
    expect(query.responses.0.text).to.equal 'response 1'

    expect(calls).to.eql 1

  it 'sets the depth in the href template'
    $.mockjax {
      url = '/queries/first/graph?depth=5'

      responseText = {
        query = {
          text = 'query 1'

          responses = [
            {
              text = 'response 1'
              query = {
                text = 'query 2'
                partial = true
                hrefTemplate = '/queries/2{?depth}'

                responses = [
                  {
                    text = 'response 1'
                  }
                ]
              }
            }
            {
              text = 'response 2'
              query = {
                text = 'query 2'
                partial = true
                hrefTemplate = '/queries/2{?depth}'

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

    calls = 0
    $.mockjax {
      url = '/queries/2?depth=5'

      response() =
        ++calls

        self.responseText = {
          query = {
            text = 'query 2'

            responses = [
              {
                text = 'response 1'
                query = {
                  text = 'query 3'

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

    graph = queryApi.firstQuery(depth = 5)!

    query = graph.query
    expect(query.text).to.equal 'query 1'
    expect(query.responses.0.text).to.equal 'response 1'

    query := query.responses.0.query()!
    expect(query.text).to.equal 'query 2'
    expect(query.responses.0.text).to.equal 'response 1'

    query := query.responses.0.query()!
    expect(query.text).to.equal 'query 3'
    expect(query.responses.0.text).to.equal 'response 1'

    query := graph.query
    query := query.responses.1.query()!
    expect(query.text).to.equal 'query 2'
    expect(query.responses.0.text).to.equal 'response 1'

    expect(calls).to.eql 1
