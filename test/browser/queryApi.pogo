$ = window.$ = window.jQuery = require 'jquery'
require 'jquery-mockjax'
createRouter = require 'mockjax-router'
_ = require 'underscore'

module.exports() =
  router = createRouter()

  model(url) =
    collection = []

    router.get(url) @(request)
      {
        statusCode = 200
        body = collection.filter @(item)
          @not item.deleted
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
      console.log('deleting ' + request)
      collection.splice(Number(request.params.id) - 1, 1)
      {
        statusCode = 204
      }

    collection

  setupBlockQueries(block) =
    block.lastQueryId = block.lastQueryId @or 0
    block.queries = block.queries @or []

  indexOfQueryIdInBlock(block, queryId) =
    indexOf(block.queries, @(q) @{ q.id == queryId })

  indexOf(array, predicate) =
    for (n = 0, n < array.length, ++n)
      if (predicate(array.(n)))
        return (n)

    -1

  router.get '/api/blocks/:blockId/queries/:queryId' @(req)
    block = blocks.(req.params.blockId - 1)

    if (block)
      setupBlockQueries(block)

      query = [q <- block.queries, q.id == req.params.queryId].0

      if (query)
        {
          body = query
        }
      else
        {
          statusCode = 404
        }
    else
      {
        statusCode = 404
      }

  router.post '/api/blocks/:blockId/queries/:queryId' @(req)
    block = blocks.(req.params.blockId - 1)

    if (block)
      setupBlockQueries(block)
      index = indexOfQueryIdInBlock(block, req.params.queryId)

      block.queries.(index) = req.body
      {
      }
    else
      {
        statusCode = 404
      }

  router.post '/api/blocks/:blockId/queries' @(req)
    block = blocks.(req.params.blockId - 1)

    if (block)
      setupBlockQueries(block)
      query = req.body

      ++block.lastQueryId
      query.id = String(block.lastQueryId)

      if (query.before)
        before = indexOfQueryIdInBlock(block, query.before)
        delete (query.before)
        block.queries.splice(before, 0, query)
      else if (query.after)
        after = indexOfQueryIdInBlock(block, query.after)
        delete (query.after)
        block.queries.splice(after + 1, 0, query)
      else
        block.queries.push(query)

      {
        statusCode = 201
        body = query
      }
    else
      {
        statusCode = 404
      }

  router.get '/api/blocks/:blockId/queries' @(req)
    block = blocks.(req.params.blockId - 1)

    if (block)
      setupBlockQueries(block)

      {
        body = block.queries.filter @(q)
          @not q.deleted
      }
    else
      {
        statusCode = 404
      }

  router.delete '/api/blocks/:blockId/queries/:queryId' @(req)
    block = blocks.(req.params.blockId - 1)

    setupBlockQueries(block)

    index = indexOfQueryIdInBlock(block, req.params.queryId)
    if (index >= 0)
      block.queries.splice(index, 1)

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
