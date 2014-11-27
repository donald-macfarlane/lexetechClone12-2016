_ = require 'underscore'
debug = require './debug'

clone(o) =
  JSON.parse(JSON.stringify(o))

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
  newContext = clone(context)
  newContext.level = response.setLevel
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

module.exports(lexemes, graph) =
  exploredQueries = {}

  findNextQuery(context) =
    findNextItem @(query) in (lexemes) startingFrom (context.coherenceIndex) matching
      query.level >= context.level \
        @and anyPredicantIn (query.predicants) foundIn (context.predicants) \
        @and block (query.block) inActiveBlocks (context.blocks)

  selectResponse (response) forQuery (query, context) =
    graph.query (query) toResponse (response)
    graph.response (response)

    newContext = newContextFromResponse (response) context (context)

    graph.debug "coherenceIndex = #(newContext.coherenceIndex)"

    nextQuery = findNextQuery(newContext)

    if (nextQuery)
      newContext.coherenceIndex = nextQuery.index
      graph.response (response) toQuery (nextQuery)
      buildGraphForQuery(nextQuery, newContext)

  query = lexemes.(0)

  buildGraphForQuery(query, context) =
    if (@not exploredQueries.(query.id))
      exploredQueries.(query.id) = true

      graph.query (query)

      [
        response <- query.responses
        selectResponse (response) forQuery (query, context)
      ]
    else
      nil

  buildGraphForQuery(query) {
    coherenceIndex = 0
    blocks = {"1" = true}
    level = 1
    predicants = {context = true}
  }

findNextItemIn (array) startingFrom (index) matching (predicate) =
  for (n = index, n < array.length, ++n)
    item = array.(n)
    if (predicate(item))
      item.index = n
      return (item)
