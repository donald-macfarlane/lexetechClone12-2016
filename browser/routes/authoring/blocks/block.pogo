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
$ = require '../../../jquery'
blockName = require './blockName'
queriesInHierarchyByLevel = require './queriesInHierarchyByLevel'
rjson = require './rjson'

reactBootstrap = require 'react-bootstrap'
DropdownButton = reactBootstrap.DropdownButton
MenuItem = reactBootstrap.MenuItem

blockPrototype = prototype {
}

module.exports = React.createFactory(React.createClass {
  mixins = [State, Navigation]

  getInitialState() =
    { blocks = [] }

  componentDidMount() =
    self.loadBlocks()
    self.loadBlock()
    self.loadQuery()
    self.loadClipboard()
    self.repositionQueriesList()
    self.resizeQueriesDiv()

    $(window).on 'scroll.repositionQueriesList'
      self.repositionQueriesList()

  componentWillUnmount() =
    $(window).off 'scroll.repositionQueriesList'

  componentDidUpdate() =
    self.repositionQueriesList()
    self.resizeQueriesDiv()

  repositionQueriesList() =
    if (self.state.blocks)
      pxNumber(x) =
        m = r/(.*)px$/.exec(x)
        if (m)
          Number(m.1)
        else
          0

      element = self.getDOMNode()
      buttons = $(element).find('.blocks-queries > .buttons')
      marginBottom = buttons.css 'margin-bottom'
      top = Math.max(0, pxNumber(marginBottom) + buttons.offset().top + buttons.height() - Math.max(0, window.scrollY))
      ol = $(element).find('.blocks-queries > ol')
      ol.css('top', top + 'px')

  resizeQueriesDiv() =
    element = self.getDOMNode()
    queriesDiv = $(element).find('.left-panel')
    queriesOl = $(element).find('.blocks-queries > ol')
    width = queriesOl.outerWidth()
    queriesDiv.css('min-width', width + 'px')

  query() =
    block = self.block()
    if (block)
      [
        q <- block.queries
        q.id == self.getParams().queryId
        q
      ].0

  componentWillReceiveProps() =
    self.loadBlock()
    self.loadQuery()

  loadBlocks() =
    blockSelf = self

    getBlocks() =
      blocks = [
        b <- self.props.http.get! '/api/blocks'
        {
          block = b
          update() =
            getQueries() =
              queries = blockSelf.props.http.get! "/api/blocks/#(b.id)/queries"
              self.queries = queries
              self.queriesHierarchy = queriesInHierarchyByLevel(queries)

            self.queriesPromise = getQueries()

            self.queriesPromise!
            blockSelf.setState { blocks = blockSelf.state.blocks }
            
            if (blockSelf.blockId() == self.block.id)
              query = blockSelf.query()
              if (query)
                blockSelf.setState { selectedQuery = query }
        }
      ]

      self.setState {
        blocks = blocks
      }

      blocks

    blocksPromise = getBlocks()

    self.setState { blocksPromise = blocksPromise }

    latestBlocks = blocksPromise!

    latestBlocks.forEach @(block)
      block.update()

    if (@not self.state.dirty @and @not self.isNewBlock())
      self.setState {
        selectedBlock = self.block()
      }

    latestBlocks

  loadClipboard() =
    clipboard = self.props.http.get!('/api/user/queries')
    if (self.isMounted())
      self.setState {
        clipboard = clipboard
      }

  addToClipboard(query) =
    self.props.http.post!("/api/user/queries", query)
    self.loadClipboard()

  loadQuery() =
    if (self.getParams().queryId)
      if (self.queryId() != self.getParams().queryId)
        query = self.query()
        if (query)
          self.setState { selectedQuery = query }
    else if (self.getRoutes().(self.getRoutes().length - 1).name == 'create_query')
      if (@not self.isNewQuery())
        self.setState { selectedQuery = queryComponent.create {} }
    else
      self.setState { selectedQuery = nil }
    
  loadBlock() =
    if (self.getParams().blockId)
      if (self.blockId() != self.getParams().blockId)
        self.setState { selectedBlock = self.block(), dirty = false }
    else if (self.getRoutes().(self.getRoutes().length - 1).name == 'create_block')
      if (@not self.isNewBlock())
        self.setState { selectedBlock = { block = {} } }
    else
      self.setState { selectedBlock = nil }

  blockId() =
    self.state.selectedBlock @and self.state.selectedBlock.block @and self.state.selectedBlock.block.id

  isNewBlock() =
    self.state.selectedBlock @and self.state.selectedBlock.block @and @not self.state.selectedBlock.block.id

  queryId() =
    self.state.selectedQuery @and self.state.selectedQuery.id

  isNewQuery() =
    self.state.selectedQuery @and @not self.state.selectedQuery.id
    
  block() =
    [b <- self.state.blocks, b.block.id == self.getParams().blockId, b].0
    
  addQuery () =
    self.transitionTo('create_query', { blockId = self.blockId() })

  nameChanged(e) =
    self.state.selectedBlock.block.name = e.target.value
    self.update()

  update(dirty = true) =
    self.setState { selectedBlock = self.state.selectedBlock, dirty = dirty }

  save() =
    self.props.http.post("/api/blocks/#(self.blockId())", self.state.selectedBlock.block)!
    self.update(dirty = false)

  create() =
    id = self.props.http.post("/api/blocks", self.state.selectedBlock.block)!.id
    self.loadBlocks()
    self.replaceWith 'block' { blockId = id }

  delete() =
    self.state.selectedBlock.block.deleted = true
    self.props.http.post("/api/blocks/#(self.blockId())", self.state.selectedBlock.block)!
    self.loadBlocks()
    self.replaceWith 'authoring'

  pasteQueryFromClipboard(query) =
    if (query :: Function)
      if (self.state.clipboardQuery)
        query(self.state.clipboardQuery)
        self.setState {
          clipboardQuery = nil
        }
    else
      if (self.state.selectedQuery)
        self.setState {
          clipboardQuery = query
        }

  cancel() =
    self.transitionTo('authoring')

  createQuery(q) =
    id = self.props.http.post("/api/blocks/#(self.blockId())/queries", q)!.id
    self.state.selectedBlock.update()
    self.replaceWith 'query' { blockId = self.blockId(), queryId = id }

  updateQuery(q) =
    self.props.http.post("/api/blocks/#(self.blockId())/queries/#(q.id)", q)!
    self.state.selectedBlock.update()

  insertQueryBefore(q) =
    q.before = q.id
    q.id = nil
    query = self.props.http.post("/api/blocks/#(self.blockId())/queries", q)!
    self.state.selectedBlock.update()
    self.replaceWith 'query' { blockId = self.blockId(), queryId = query.id }

  insertQueryAfter(q) =
    q.after = q.id
    q.id = nil
    query = self.props.http.post("/api/blocks/#(self.blockId())/queries", q)!
    self.state.selectedBlock.update()
    self.replaceWith 'query' { blockId = self.blockId(), queryId = query.id }

  removeQuery(q) =
    q.deleted = true
    self.props.http.post ("/api/blocks/#(self.blockId())/queries/#(q.id)", q)!
    self.setState { selectedQuery = nil }
    self.state.selectedBlock.update()
    self.replaceWith 'block' { blockId = self.blockId() }

  addBlock() =
    self.transitionTo 'create_block'

  toggleClipboard(ev) =
    ev.preventDefault()
    self.setState {
      showClipboard = @not self.state.showClipboard
    }

  textValue(value) = value @or ''

  render() =
    r 'div' { className = 'edit-block-query' } (
      r 'div' { className = 'left-panel' } (
        r 'div' { className = 'clipboard' } (
          r 'h2' {} (
            r 'a' { href = '#', onClick = self.toggleClipboard } ("Clipboard", if (self.state.clipboard) @{ " (#(self.state.clipboard.length))" })
          )
          if (self.state.showClipboard)
            r 'ol' {} [
              if (self.state.clipboard)
                [
                  q <- self.state.clipboard

                  pasteFromClipboard(ev) =
                    self.pasteQueryFromClipboard(q)
                    ev.preventDefault()
                    
                  r 'li' { onClick = pasteFromClipboard } (r 'h4' {} (q.name))
                ]
            ]
        )

        if (self.state.blocks)
          renderQueries(block, queries) =

            r 'ol' {} [
              tree <- queries

              selectQuery(ev) =
                self.replaceWith 'query' { blockId = block.id, queryId = tree.query.id }
                ev.stopPropagation()

              show(ev) =
                tree.hideQueries = false
                self.setState { blocks = self.state.blocks }
                ev.stopPropagation()

              hide(ev) =
                tree.hideQueries = true
                self.setState { blocks = self.state.blocks }
                ev.stopPropagation()

              selectedClass = if (self.queryId() == tree.query.id)
                'selected'

              r 'li' { onClick = selectQuery, className = selectedClass } (
                r 'h4' {} (
                  if (tree.queries)
                    if (tree.hideQueries)
                      r 'button' { className = 'toggle', onClick = show } (r 'span' {} '+')
                    else
                      r 'button' { className = 'toggle', onClick = hide } (r 'span' {} '-')

                  tree.query.name
                )

                if (@not tree.hideQueries @and tree.queries)
                  renderQueries(block, tree.queries)
              )
            ]

          r 'div' { className = 'blocks-queries' } (
            r 'h2' {} 'Blocks'
            r 'div' { className = 'buttons' } (
              r 'button' { onClick = self.addBlock } 'Add Block'
            )
            r 'ol' {} [
              blockViewModel <- self.state.blocks
              block = blockViewModel.block

              selectBlock(ev) =
                self.replaceWith 'block' { blockId = block.id }
                ev.stopPropagation()

              show(ev) =
                blockViewModel.hideQueries = false
                self.setState { blocks = self.state.blocks }
                ev.stopPropagation()

              hide(ev) =
                blockViewModel.hideQueries = true
                self.setState { blocks = self.state.blocks }
                ev.stopPropagation()

              selectedClass = if (self.blockId() == block.id)
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

                if (@not blockViewModel.hideQueries @and blockViewModel.queriesHierarchy)
                  renderQueries(block, blockViewModel.queriesHierarchy)
              )
            ]
          )
      )

      if (self.state.selectedBlock @and self.state.selectedBlock.block)
        addQuery() =
          self.transitionTo 'create_query' { blockId = self.blockId() }

        r 'div' { className = 'edit-block' } (
          r 'h2' {} ('Block')
          r 'div' { className = 'buttons' } (
            if (@not self.blockId())
              r 'button' { className = 'create', onClick = self.create } 'Create'
            else if (self.state.dirty)
              r 'button' { className = 'save', onClick = self.save } 'Save'

            if (self.blockId())
              r 'button' { className = 'delete', onClick = self.delete } 'Delete'

            if (self.state.dirty @or self.isNewBlock())
              r 'button' { className = 'cancel', onClick = self.cancel } 'Cancel'
            else
              r 'button' { className = 'cancel', onClick = self.cancel } 'Close'

          )
          r 'ul' {} (
            r 'li' {} (
              r 'label' { htmlFor = 'block_name' } 'Name'
              r 'input' { id = 'block_name', type = 'text', value = self.textValue(self.state.selectedBlock.block.name), onChange = self.nameChanged }
            )
          )
          if (self.blockId() @and self.state.selectedBlock.queries @and self.state.selectedBlock.queries.length == 0)
            r 'ul' {} (
              r 'li' {} (
                r 'button' { onClick = addQuery } 'Add Query'
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
                pasteQueryFromClipboard = self.pasteQueryFromClipboard
                addToClipboard = self.addToClipboard
              }
            ]
        )
      else
        r 'div' {}
    )
})
