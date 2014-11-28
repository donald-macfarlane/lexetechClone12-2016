_ = require 'underscore'
debug = require './debug'
createContext = require './context'

cloneContext(c) =
  blocks = {}
  for @(bk) in (c.blocks)
    blocks.(bk) = true

  predicants = {}
  for @(pk) in (c.predicants)
    predicants.(pk) = true

  createContext {
    coherenceIndex = c.coherenceIndex
    blocks = blocks
    level = c.level
    depth = c.depth
    predicants = predicants
  }

actions = {
  none (context) = nil
  email (context) = nil

  addBlocks (context, blocks, ...) =
    for each @(block) in (blocks)
      context.blocks.(block) = true

  setBlocks (context, blocks, ...) =
    context.blocks = {}
    for each @(block) in (blocks)
      context.blocks.(block) = true

  setVariable (context, variable, value) = nil

  repeatLexeme (context) =
    --context.coherenceIndex

  loopBack (context) = nil
}

newContextFromResponse (response) context (context) =
  newContext = cloneContext(context)
  newContext.level = response.setLevel
  ++newContext.depth
  ++newContext.coherenceIndex

  action = actions.(response.action.name)
  action(newContext, response.action.arguments, ...)

  for each @(p) in (response.predicants)
    newContext.predicants.(p) = true

  newContext

anyPredicantIn (predicants) foundIn (currentPredicants) =
  if (predicants.length > 0)
    _.any(predicants) @(p)
      currentPredicants.(p)
  else
    true

block (block) inActiveBlocks (blocks) =
  blocks.(block)

createVisitedQueries() =
  queries = {}
  hits = 0
  skips = 0

  {
    hasVisitedQuery (query) context (context) =
      q = queries.(query.id)

      if (q)
        if (q.(context.key()))
          ++skips
          true
        else
          ++hits
          false
      else
        ++hits
        false

    visitedQuery (query) context (context) =
      q = queries.(query.id)

      if (@not q)
        q := queries.(query.id) = {}

      q.(context.key()) = true
  }

module.exports(lexemes, graph, maxDepth = 0) =
  unexploredQueries = []
  visitedQueries = createVisitedQueries()

  findNextQuery(context) =
    findNextItem @(query) in (lexemes) startingFrom (context.coherenceIndex) matching
      query.level <= context.level \
        @and anyPredicantIn (query.predicants) foundIn (context.predicants) \
        @and block (query.block) inActiveBlocks (context.blocks)

  selectResponse (response) forQuery (query, context) =
    graph.query (query) toResponse (response)
    graph.response (response)

    newContext = newContextFromResponse (response) context (context)

    if (maxDepth == 0 @or newContext.depth < maxDepth)
      nextQuery = findNextQuery(newContext)
      graph.response (response) toQuery (nextQuery)

      if (nextQuery)
        newContext.coherenceIndex = nextQuery.index
        if (@not visitedQueries.hasVisitedQuery (nextQuery) context (newContext))
          visitedQueries.visitedQuery (nextQuery) context (newContext)
          unexploredQueries.push {
            query = nextQuery
            context = newContext
          }

  query = lexemes.(0)

  buildGraphForQuery(query, context) =
    graph.query (query)

    [
      response <- query.responses
      selectResponse (response) forQuery (query, context)
    ]

  unexploredQueries.push {
    query = query
    context = createContext {
      coherenceIndex = 0
      blocks = {"1" = true}
      level = 1
      predicants = {context = true}
      depth = 0
    }
  }

  every(n) =
    i = -1

    @(block)
      ++i
      if (i >= n)
        block()
        i := 0

  everySoOften = every 1000

  numberOfQueries = 0
  while(unexploredQueries.length > 0)
    task = unexploredQueries.shift()
    everySoOften
      graph.debug "exploring #(unexploredQueries.length):#(numberOfQueries)"

    buildGraphForQuery(task.query, task.context)
    ++numberOfQueries

findNextItemIn (array) startingFrom (index) matching (predicate) =
  for (n = index, n < array.length, ++n)
    item = array.(n)
    if (predicate(item))
      item.index = n
      return (item)
