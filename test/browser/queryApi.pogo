createRouter = require 'mock-xhr-router'
_ = require 'underscore'

window._debug = require 'debug'

module.exports() =
  router = createRouter()

  model(url, hrefs = false, outgoing() = nil) =
    collection = []

    router.get(url) @(request)
      notDeleted = collection.filter @(item)
        @not item.deleted

      withHrefs =
        if (hrefs)
          notDeleted.map @(item, index)
            item.href = "#(url)/#(index + 1)"
            item
        else
          notDeleted

      withHrefs.forEach(outgoing)

      {
        statusCode = 200
        body = withHrefs
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

    postPut(request) =
      collection.(Number(request.params.id) - 1) = request.body

      if (hrefs)
        request.body.href = url + '/' + request.params.id

      {
        statusCode = 200
        body = request.body
      }

    router.post(url + '/:id', postPut)
    router.put(url + '/:id', postPut)

    router.get(url + '/:id') @(request)
      body = collection.(Number(request.params.id) - 1)
      outgoing(body)
      
      if (body)
        {
          body = body
        }
      else
        {
          statusCode = 404
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

  router.get '/api/user/documents/current' @(req)
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

  router.get '/api/users/search' @(req)
    query = req.params.q

    foundUsers = users.filter @(user)
      user.email.indexOf(query) >= 0 @or user.firstName.indexOf(query) >= 0 @or user.familyName.indexOf(query)

    {
      body = foundUsers
    }

  userQueries = []

  blocks = model('/api/blocks')
  clipboard = model('/api/user/queries', hrefs = true)
  documents = model('/api/user/documents', hrefs = true)
  users = model(
    '/api/users'
    hrefs = true
    outgoing(user) =
      user.resetPasswordTokenHref = '/api/users/' + user.id + '/resetpasswordtoken'
  )

  router.post '/api/users/:id/resetpasswordtoken' @(req)
    {
      body = { token = req.id + '_token' }
    }

  router.get '/api/predicants' @(req)
    predicants.forEach @(pred, index)
      pred.href = '/api/predicants/' + (index + 1)

    {
      body = _.indexBy(predicants, 'id')
    }

  predicants = model('/api/predicants', hrefs = true)

  router.get '/api/predicants/:predicantId/usages' @(req)
    predicantId = req.params.predicantId

    queries = [
      b <- blocks
      q <- b.queries
      queriesById.(q)
    ]

    usingQueries = [item <- queries, item.predicants.indexOf(predicantId) >= 0, item]
    usingResponses = [
      q <- queries
      qr = {
        query = q
        responses = [
          r <- q.responses
          r.predicants.indexOf(predicantId) >= 0
          r
        ]
      }
      qr.responses.length > 0
      qr
    ]

    {
      body = {
        queries = usingQueries
        responses = usingResponses
      }
    }

  {
    blocks = blocks
    predicants = predicants
    userQueries = userQueries
    clipboard = clipboard
    documents = documents
    users = users

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
