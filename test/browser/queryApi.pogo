createRouter = require 'mockjax-router'
_ = require 'underscore'

module.exports() =
  router = createRouter()

  model(url, hrefs = false) =
    collection = []

    router.get(url) @(request)
      {
        statusCode = 200
        body = collection.filter @(item)
          @not item.deleted
      }

    router.post(url) @(request)
      collection.push(request.body)
      request.body.id = String(collection.length)

      if (hrefs)
        request.body.href = url + '/' + request.body.id

      {
        statusCode = 201
        body = request.body
      }

    router.post(url + '/:id') @(request)
      collection.(Number(request.params.id) - 1) = request.body

      if (hrefs)
        request.body.href = url + '/' + request.params.id

      {
        statusCode = 200
      }

    router.get(url + '/:id') @(request)
      body = collection.(Number(request.params.id) - 1)
      {
        body = body
      }

    router.delete(url + '/:id') @(request)
      collection.splice(Number(request.params.id) - 1, 1)
      {
        statusCode = 204
      }

    collection

  queriesById = {}
  lastQueryId = 0
  addQuery(query) =
    ++lastQueryId
    query.id = String(lastQueryId)
    queriesById.(query.id) = query

  setupBlockQueries(block) =
    block.queries = block.queries @or []

  indexOfQueryIdInBlock(block, queryId) =
    indexOf(block.queries, @(q) @{ q.id == queryId })

  indexOf(array, predicate) =
    for (n = 0, n < array.length, ++n)
      if (predicate(array.(n)))
        return (n)

    -1

  router.get '/api/blocks/:blockId/queries/:queryId' @(req)
    query = queriesById.(req.params.queryId)

    if (query)
      {
        body = query
      }
    else
      {
        statusCode = 404
      }

  router.post '/api/blocks/:blockId/queries/:queryId' @(req)
    block = blocks.(req.params.blockId - 1)

    if (block)
      setupBlockQueries(block)
      index = block.queries.indexOf(req.params.queryId)

      if (req.body.before)
        beforeIndex = block.queries.indexOf(req.body.before)
        block.queries.splice(beforeIndex, 0, block.queries.splice(index, 1).0)
      else if (req.body.after)
        afterIndex = block.queries.indexOf(req.body.after)
        block.queries.splice(afterIndex + 1, 0, block.queries.splice(index, 1).0)

      queriesById.(req.params.queryId) = req.body

      {
        body = req.body
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

      addQuery(query)

      if (query.before)
        beforeIndex = block.queries.indexOf(query.before)
        delete (query.before)
        block.queries.splice(beforeIndex, 0, query.id)
      else if (query.after)
        afterIndex = block.queries.indexOf(query.after)
        delete (query.after)
        block.queries.splice(afterIndex + 1, 0, query.id)
      else
        block.queries.push(query.id)

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
        body = block.queries.map @(qid)
          queriesById.(qid)
        .filter @(q)
          @not q.deleted
      }
    else
      {
        statusCode = 404
      }

  router.delete '/api/blocks/:blockId/queries/:queryId' @(req)
    block = blocks.(req.params.blockId - 1)

    setupBlockQueries(block)

    index = block.queries.indexOf(req.params.queryId)
    if (index >= 0)
      block.queries.splice(index, 1)
      delete (queriesById.(req.params.queryId))

    {
      statusCode = 204
    }

  router.get '/api/user/documents/last' @(req)
    if (documents.length)
      {
        body = documents.0
      }
    else
      {
        statusCode = 404
      }

  router.get '/api/queries/:queryId' @(req)
    query = queriesById.(req.params.queryId)

    if (query)
      {
        body = query
      }
    else
      {
        statusCode = 404
      }

  userQueries = []

  blocks = model('/api/blocks')
  clipboard = model('/api/user/queries')
  documents = model('/api/user/documents', hrefs = true)
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
    documents = documents
    setLexicon(lexicon) =
      lexiconBlocks = lexicon.blocks.map @(b)
        b.queries.forEach @(q)
          addQuery(q)

        {
          id = b.id
          name = b.name
          queries = b.queries.map @(q) @{ q.id }
        }

      blocks.push(lexiconBlocks, ...)

    lexicon() =
      lexiconBlocks = blocks.map @(b)
        {
          id = b.id
          name = b.name

          queries = b.queries.map @(id)
            queriesById.(id)
        }

      {
        blocks = lexiconBlocks
      }
  }
