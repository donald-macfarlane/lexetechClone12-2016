_ = require 'underscore'
createContext = require './context'
cache = require '../common/cache'
lexemeApi = require '../browser/lexemeApi'

cloneContext(c) =
  predicants = {}

  Object.keys(c.predicants).forEach @(pk)
    predicants.(pk) = true

  blockStack = JSON.parse(JSON.stringify(c.blockStack))

  createContext {
    coherenceIndex = c.coherenceIndex
    block = c.block
    blocks = c.blocks.slice 0
    level = c.level
    predicants = predicants
    blockStack = blockStack
  }

actions = {
  none (response, context) = nil
  email (response, context) = nil

  addBlocks (response, context, blocks, ...) =
    context.pushBlockStack()

    context.coherenceIndex = 0
    context.block = blocks.shift()
    context.blocks = blocks

  setBlocks (response, context, blocks, ...) =
    context.blocks = blocks.slice 0

    nextBlock = context.blocks.shift()

    if (String(nextBlock) != String(context.block))
      context.block = nextBlock
      context.coherenceIndex = 0

  setVariable (response, context, variable, value) = nil

  repeatLexeme (response, context) =
    --context.coherenceIndex
    response.repeating = true

  loopBack (response, context) = nil
}

newContextFromResponse (response) context (context) =
  newContext = cloneContext(context)
  newContext.level = response.setLevel
  ++newContext.coherenceIndex

  if (response.actions)
    for each @(responseAction) in (response.actions)
      action = actions.(responseAction.name)
      action(response, newContext, responseAction.arguments, ...)

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

findNextQuery(api, context) =
  blocksSearched = []

  findNext(context) =
    blocksSearched.push(context.block)

    query = findNextQueryInCurrentBlock(api, context)!
    if (@not query)
      if (context.blocks.length > 0)
        context.block = context.blocks.shift()
        context.coherenceIndex = 0
        findNext(context)!
      else if (context.blockStack.length > 0)
        context.popBlockStack()
        findNext(context)!
    else
      query

  result = {}
  result.query = findNext(context)!

  result.blocksSearched = blocksSearched

  result

findNextQueryInCurrentBlock(api, context) =
  findNextItem! @(query) in (api.block(context.block)) startingFrom (context.coherenceIndex) matching
    query.level <= context.level \
      @and anyPredicantIn (query.predicants) foundIn (context.predicants)

preloadQueryGraph(query, depth) =
  if (depth > 0 @and query.query)
    [
      r <- query.responses
      preloadQueryGraph(r.query(preload = false)!, depth - 1)!
    ]

module.exports(api = lexemeApi()) =
  queryCache = cache()

  queryGraph (next, context) =
    graph = {
      query = next.query

      context = next.context
      previousContext = next.previousContext
      nextContext = next.nextContext
      blocksSearched = next.blocksSearched
    }

    if (next.query)
      graph.responses = [
        r <- next.query.responses
        {
          text = r.text
          styles = r.styles

          query(preload = true) =
            if (@not self._query)
              self._query = nextQueryForResponse(r, context)

            if (preload @and @not self.preloaded)
              @{
                self.preloaded = true
                preloadQueryGraph(self._query!, 4)!
              }()

            self._query
        }
      ]

    graph

  nextQueryForResponse (response, context) =
    newContext = newContextFromResponse (response) context (context)

    queryCache.cacheBy "#(newContext.coherenceIndex):#(newContext.key())"!
      originalContext = cloneContext(newContext)

      next = findNextQuery!(api, newContext)

      if (next.query)
        newContext.coherenceIndex = next.query.index

      next.previousContext = context
      next.context = originalContext
      next.nextContext = newContext

      queryGraph (next, newContext)

  {
    firstQueryGraph(preload = true) =
      query = api.block(1).query(0)!

      firstPredicants = {}
      query.predicants.forEach @(p)
        firstPredicants.(p) = true

      context = createContext {
        coherenceIndex = 0
        block = query.block
        blocks = []
        level = 1
        predicants = firstPredicants
        blockStack = []
      }

      graph = queryGraph ({ query = query, context = context }, context)
      if (preload)
        preloadQueryGraph(graph, 4)

      graph
  }

findNextItemIn (block) startingFrom (index) matching (predicate) =
  if (index < block.length()!)
    item = block.query(index)!

    if (predicate(item))
      item.index = index
      item
    else
      findNextItemIn (block) startingFrom (index + 1) matching (predicate)!
