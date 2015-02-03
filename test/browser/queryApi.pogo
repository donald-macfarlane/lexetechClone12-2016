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

    router.post(url + '/:id') @(request)
      collection.(Number(request.params.id) - 1) = request.body
      {
        statusCode = 200
      }

    router.delete(url + '/:id') @(request)
      collection.splice(Number(request.params.id) - 1, 1)
      {
        statusCode = 204
      }

    collection

  router.get '/api/blocks/:blockId/queries/:queryId' @(req)
    block = blocks.(req.params.blockId - 1)
    block.queries = block.queries @or []
    {
      body = block.queries.(req.params.queryId)
    }

  router.post '/api/blocks/:blockId/queries/:queryId' @(req)
    block = blocks.(req.params.blockId - 1)

    if (block)
      block.queries = block.queries @or []
      block.queries.(Number(req.params.queryId) - 1) = req.body
      {
      }
    else
      {
        statusCode = 404
      }

  router.post '/api/blocks/:blockId/queries' @(req)
    block = blocks.(req.params.blockId - 1)
    block.queries = block.queries @or []
    block.queries.push(req.body)
    req.body.id = String(block.queries.length)
    {
      statusCode = 201
      body = req.body
    }

  router.get '/api/blocks/:blockId/queries' @(req)
    block = blocks.(req.params.blockId - 1)

    if (block)
      block.queries = block.queries @or []

      {
        body = block.queries
      }
    else
      {
        statusCode = 404
      }

  router.delete '/api/blocks/:blockId/queries/:queryId' @(req)
    block = blocks.(req.params.blockId - 1)
    block.queries = block.queries @or []
    if (block.queries)
      block.queries.splice(Number(req.params.queryId) - 1, 1)

    {
      statusCode = 204
    }

  userQueries = []

  blocks = model('/api/blocks')
  clipboard = model('/api/user/queries')
  predicants = []

  router.get '/api/predicants' @(req)
    {
      body = _.indexBy(predicants, 'id')
    }

  {
    blocks = blocks
    predicants = predicants
    userQueries = userQueries
    clipboard = clipboard
  }
