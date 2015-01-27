React = require 'react'
ReactRouter = require 'react-router'
State = ReactRouter.State
Link = React.createFactory(ReactRouter.Link)
r = React.createElement
Navigation = ReactRouter.Navigation
_ = require 'underscore'
queryComponent = require './queries/query'
sortable = require './sortable'
moveItemInFromTo = require './moveItemInFromTo'
$ = require 'jquery'
blockName = require './blockName'
queriesInHierarchyByLevel = require './queriesInHierarchyByLevel'

module.exports = React.createFactory(React.createClass {
  mixins = [State, Navigation]

  getInitialState() =
    { selectedBlock = { name = '' }, queries = [], blocks = [] }

  componentDidMount() =
    if (self.getParams().blockId)
      self.loadBlock()

    self.loadBlocks()
    self.repositionQueriesList()
    self.resizeQueriesDiv()

    $(window).on 'scroll.repositionQueriesList'
      self.repositionQueriesList()

  componentWillUnmount() =
    $(window).off 'scroll.repositionQueriesList'

  componentDidUpdate() =
    self.resizeQueriesDiv()

  repositionQueriesList() =
    if (self.state.selectedBlock.id)
      pxNumber(x) =
        m = r/(.*)px$/.exec(x)
        if (m)
          Number(m.1)
        else
          0

      element = self.getDOMNode()
      h2 = $(element).find('.blocks-queries > h2')
      marginBottom = h2.css 'margin-bottom'
      top = Math.max(0, pxNumber(marginBottom) + h2.offset().top + h2.height() - Math.max(0, window.scrollY))
      ol = $(element).find('.blocks-queries > ol')
      ol.css('top', top + 'px')

  resizeQueriesDiv() =
    element = self.getDOMNode()
    queriesDiv = $(element).find('.blocks-queries')
    queriesOl = $(element).find('.blocks-queries > ol')
    width = queriesOl.width()
    queriesDiv.css('min-width', width)

  query() =
    [query <- self.state.queries, query.id == self.getParams().queryId, query].0

  componentWillReceiveProps() =
    currentId = self.state.selectedQuery @and self.state.selectedQuery.id

    if (currentId != self.getParams().queryId)
      if (self.getParams().queryId)
        self.setState { selectedQuery = self.query() }
      else if (self.getRoutes().(self.getRoutes().length - 1).name == 'create_query')
        self.setState { selectedQuery = queryComponent.create {} }
      else
        self.setState { selectedQuery = nil }

    currentBlockId = self.state.selectedBlock @and self.state.selectedBlock.id

    if (currentBlockId @and self.getParams().blockId @and currentBlockId != self.getParams().blockId)
      self.loadBlock()

  queries() =
    path = "/api/blocks/#(self.getParams().blockId)/queries"
    self.props.http.get(path)!

  loadBlocks() =
    blockSelf = self

    blocks = [
      b <- self.props.http.get! '/api/blocks'
      {
        block = b
        update() =
          self.queries = queriesInHierarchyByLevel(blockSelf.props.http.get! "/api/blocks/#(b.id)/queries")
          blockSelf.setState { blocks = blocks }
      }
    ]

    blocks.forEach @(block)
      block.update()

    self.setState { blocks = blocks }

  loadBlock() =
    q = self.queries()
    b = self.block()

    self.setState { selectedBlock = b! , queries = q! }

    if (self.getParams().queryId)
      self.setState { selectedQuery = self.query() }
    else if (self.getRoutes().(self.getRoutes().length - 1).name == 'create_query')
      self.setState { selectedQuery = queryComponent.create {} }
    
  block() =
    path = '/api/blocks/' + self.getParams().blockId
    self.props.http.get(path)!
    
  addQuery () =
    self.setState { selectedQuery = queryComponent.create {} }
    self.transitionTo('create_query', { blockId = self.state.selectedBlock.id })

  nameChanged(e) =
    self.state.selectedBlock.name = e.target.value
    self.update()

  update(dirty = true) =
    self.setState { selectedBlock = self.state.selectedBlock, dirty = dirty }

  save() =
    self.props.http.post("/api/blocks/#(self.state.selectedBlock.id)", _.omit(self.state.selectedBlock, 'queries'))!
    self.update(dirty = false)

  create() =
    self.state.selectedBlock.id = self.props.http.post("/api/blocks", _.omit(self.state.selectedBlock, 'queries'))!.id
    self.replaceWith 'block' { blockId = self.state.selectedBlock.id }
    self.update(dirty = false)

  cancel() =
    self.transitionTo('authoring')

  createQuery(q) =
    query = self.props.http.post("/api/blocks/#(self.getParams().blockId)/queries", q)!
    self.setState {
      queries = self.queries()!
      selectedQuery = query
    }
    self.replaceWith 'query' { blockId = self.getParams().blockId, queryId = query.id }

  updateQuery(q) =
    self.props.http.post("/api/blocks/#(self.getParams().blockId)/queries/#(q.id)", q)!
    self.setState { queries = self.queries()! }

  insertQueryBefore(q) =
    q.before = q.id
    q.id = nil
    query = self.props.http.post("/api/blocks/#(self.getParams().blockId)/queries", q)!
    self.setState {
      queries = self.queries()!
      selectedQuery = query
    }
    self.replaceWith 'query' { blockId = self.getParams().blockId, queryId = query.id }

  insertQueryAfter(q) =
    q.after = q.id
    q.id = nil
    query = self.props.http.post("/api/blocks/#(self.getParams().blockId)/queries", q)!
    self.setState {
      queries = self.queries()!
      selectedQuery = query
    }
    self.replaceWith 'query' { blockId = self.getParams().blockId, queryId = query.id }

  removeQuery(q) =
    self.state.queries = _.without(self.state.queries, q)
    self.props.http.delete ("/api/blocks/#(self.getParams().blockId)/queries/#(q.id)")!
    queries = self.props.http.get "/api/blocks/#(self.getParams().blockId)/queries"!
    self.setState { queries = queries }
    if (q.id == self.state.selectedQuery.id)
      self.setState { selectedQuery = nil }

  render() =
    r 'div' { className = 'edit-block-query' } (
      if (self.state.blocks)
        renderQueries(block, queries) =

          r 'ol' {} [
            query <- queries

            selectQuery(ev) =
              self.replaceWith 'query' { blockId = block.id, queryId = query.id }
              ev.stopPropagation()

            show(ev) =
              query.hideQueries = false
              self.setState { blocks = self.state.blocks }
              ev.stopPropagation()

            hide(ev) =
              query.hideQueries = true
              self.setState { blocks = self.state.blocks }
              ev.stopPropagation()

            selectedClass = if (self.state.selectedQuery @and query.id == self.state.selectedQuery.id)
              'selected'

            r 'li' { onClick = selectQuery, className = selectedClass } (
              r 'h4' {} (
                if (query.queries)
                  if (query.hideQueries)
                    r 'button' { className = 'toggle', onClick = show } (r 'span' {} '+')
                  else
                    r 'button' { className = 'toggle', onClick = hide } (r 'span' {} '-')

                query.name
              )

              if (@not query.hideQueries @and query.queries)
                renderQueries(block, query.queries)
            )
          ]

        r 'div' { className = 'blocks-queries' } (
          r 'h2' {} 'Blocks'
          r 'ol' {} [
            blockViewModel <- self.state.blocks
            block = blockViewModel.block

            selectBlock() =
              self.replaceWith 'block' { blockId = block.id }

            show(ev) =
              blockViewModel.hideQueries = false
              self.setState { blocks = self.state.blocks }
              ev.stopPropagation()

            hide(ev) =
              blockViewModel.hideQueries = true
              self.setState { blocks = self.state.blocks }
              ev.stopPropagation()

            selectedClass = if (self.state.selectedBlock @and block.id == self.state.selectedBlock.id)
              'selected'

            r 'li' { onClick = selectBlock, className = selectedClass } (

              r 'h3' {} (
                if (blockViewModel.queries @and blockViewModel.queries.length > 0)
                  if (blockViewModel.hideQueries)
                    r 'button' { className = 'toggle', onClick = show } '+'
                  else
                    r 'button' { className = 'toggle', onClick = hide } '-'

                blockName(block)
              )

              if (@not blockViewModel.hideQueries @and blockViewModel.queries)
                renderQueries(block, blockViewModel.queries)
            )
          ]
        )

      /*
      r 'div' { className = 'edit-block query-list' } (
        if (self.getParams().blockId)
          r 'div' { className = 'queries' } (
            r 'h2' {} 'Queries'

            if (self.state.queries.length == 0)
              r 'label' {} 'This block has no queries'
            else
              r 'ol' {} [
                q <- self.state.queries

                selected = self.state.selectedQuery @and self.state.selectedQuery.id == q.id

                select() =
                  self.transitionTo 'query' { blockId = self.state.selectedBlock.id, queryId = q.id }

                r 'li' { className = if (selected ) @{ 'selected' }, key = q.id, onClick = select } (
                  r 'h3' { className = 'name' } (
                    [
                      i <- [1..(q.level)]
                      r 'span' { className = 'level-indent' }
                    ]
                    q.name
                  )
                )
              ]

            if (self.state.queries.length == 0)
              r 'button' { onClick = self.addQuery } 'Add Query'
          )
      )
      */

      r 'div' { className = 'edit-block' } (
        r 'div' { className = 'buttons' } (
          if (@not self.getParams().blockId)
            r 'button' { className = 'create', onClick = self.create } 'Create'
          else if (self.state.dirty)
            r 'button' { className = 'save', onClick = self.save } 'Save'

          if (@not self.state.selectedQuery)
            if (self.state.dirty)
              r 'button' { className = 'cancel', onClick = self.cancel } 'Cancel'
            else
              r 'button' { className = 'cancel', onClick = self.cancel } 'Close'
        )
        r 'h2' {} ('Block')
        r 'ul' {} (
          r 'li' {} (
            r 'label' { htmlFor = 'block_name' } 'Name'
            r 'input' { id = 'block_name', type = 'text', value = self.state.selectedBlock.name, onChange = self.nameChanged }
          )
        )
        if (self.state.selectedQuery)
          [
            r 'hr' {}
            queryComponent {
              http = self.props.http
              query = self.state.selectedQuery
              removeQuery = self.removeQuery
              updateQuery = self.updateQuery
              createQuery = self.createQuery
              insertQueryBefore = self.insertQueryBefore
              insertQueryAfter = self.insertQueryAfter
            }
          ]
      )
    )
})
