$ = window.$ = window.jQuery = require 'jquery'
require '../../bower_components/jquery-mockjax/jquery.mockjax.js'
createRouter = require './router'
_ = require 'underscore'

module.exports() =
  router = createRouter()

  model(url) =
    collection = []

    router.get(url) @(request)
      {
        statusCode = 200
        body = collection
      }

    router.post(url) @(request)
      collection.push(request.body)
      request.body.id = String(blocks.length)
      {
        statusCode = 201
        body = request.body
      }

    router.put(url + '/:id') @(request)
      collection.(Number(request.params.id) + 1) = request.body
      {
        statusCode = 200
      }

    collection

  router.get '/api/blocks/:blockid/queries/:queryid' @(req)
    block = blocks.(req.params.blockid - 1)
    block.queries = block.queries @or []
    {
      body = block.queries.(req.params.queryid)
    }

  router.post '/api/blocks/:blockid/queries' @(req)
    block = blocks.(req.params.blockid - 1)
    block.queries = block.queries @or []
    block.queries.push(req.body)
    req.body.id = String(block.queries.length)
    {
      statusCode = 201
      body = req.body
    }

  router.get '/api/blocks/:blockid/queries' @(req)
    block = blocks.(req.params.blockid - 1)
    block.queries = block.queries @or []

    {
      body = block.queries
    }

  blocks = model('/api/blocks')
  predicants = []

  router.get '/api/predicants' @(req)
    {
      body = _.indexBy(predicants, 'id')
    }

  {
    blocks = blocks
    predicants = predicants
  }
