React = require 'react'
ReactRouter = require 'react-router'
State = ReactRouter.State
Link = React.createFactory(ReactRouter.Link)
r = React.createElement
Navigation = ReactRouter.Navigation
_ = require 'underscore'
queryComponent = require './queries/query'
draggable = require './draggable'
moveItemInFromTo = require './moveItemInFromTo'
$ = require 'jquery'

module.exports = React.createFactory(React.createClass {
  mixins = [State, Navigation]

  getInitialState() =
    { block = { name = '' }, queries = [] }

  componentDidMount() =
    if (self.getParams().blockId)
      q = self.queries()
      b = self.block()

      self.setState { block = b! , queries = q! }

      if (self.getParams().queryId)
        self.setState { selectedQuery = self.query() }
      else if (self.getRoutes().(self.getRoutes().length - 1).name == 'create_query')
        self.setState { selectedQuery = queryComponent.create {} }

    self.repositionQueriesList()
    self.resizeQueriesDiv()

    $(window).on 'scroll.repositionQueriesList'
      self.repositionQueriesList()

  componentWillUnmount() =
    $(window).off 'scroll.repositionQueriesList'

  componentDidUpdate() =
    self.resizeQueriesDiv()

  repositionQueriesList() =
    pxNumber(x) =
      m = r/(.*)px$/.exec(x)
      if (m)
        Number(m.1)
      else
        0

    element = self.getDOMNode()
    h2 = $(element).find('.queries > h2')
    marginBottom = h2.css 'margin-bottom'
    top = Math.max(0, pxNumber(marginBottom) + h2.offset().top + h2.height() - Math.max(0, window.scrollY))
    ol = $(element).find('.queries > ol')
    ol.css('top', top + 'px')

  resizeQueriesDiv() =
    element = self.getDOMNode()
    queriesDiv = $(element).find('.edit-block.query-list')
    queriesOl = $(element).find('.queries > ol')
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

  queries() =
    path = "/api/blocks/#(self.getParams().blockId)/queries"
    self.props.http.get(path)!
    
  block() =
    path = '/api/blocks/' + self.getParams().blockId
    self.props.http.get(path)!
    
  addQuery () =
    self.setState { selectedQuery = queryComponent.create {} }
    self.transitionTo('create_query', { blockId = self.state.block.id })

  nameChanged(e) =
    self.state.block.name = e.target.value
    self.update()

  update(dirty = true) =
    self.setState { block = self.state.block, dirty = dirty }

  save() =
    self.props.http.post("/api/blocks/#(self.state.block.id)", _.omit(self.state.block, 'queries'))!
    self.update(dirty = false)

  create() =
    self.state.block.id = self.props.http.post("/api/blocks", _.omit(self.state.block, 'queries'))!.id
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

  render() =
    r 'div' { className = 'edit-block-query' } (
      r 'div' { className = 'edit-block query-list' } (
        if (self.state.block.id)
          r 'div' { className = 'queries' } (
            r 'h2' {} 'Queries'

            if (self.state.queries.length == 0)
              r 'label' {} 'This block has no queries'
            else
              itemMoved(from, to) =
                q = self.state.queries.(from)

                movement = if (from < to)
                  {
                    id = q.id
                    after = self.state.queries.(to).id
                  }
                else
                  {
                    id = q.id
                    before = self.state.queries.(to).id
                  }

                moveItemIn (self.state.queries) from (from) to (to)
                self.setState { queries = self.state.queries }
                self.updateQuery(movement)

              render() =
                r 'ol' {} [
                  q <- self.state.queries

                  remove () =
                    self.state.queries = _.without(self.state.queries, q)
                    self.props.http.delete ("/api/blocks/#(self.getParams().blockId)/queries/#(q.id)")!
                    queries = self.props.http.get "/api/blocks/#(self.getParams().blockId)/queries"!
                    self.setState { queries = queries }
                    if (q.id == self.state.selectedQuery.id)
                      self.setState { selectedQuery = nil }

                  selected = self.state.selectedQuery @and self.state.selectedQuery.id == q.id

                  select() =
                    self.transitionTo 'query' { blockId = self.state.block.id, queryId = q.id }

                  r 'li' { className = if (selected ) @{ 'selected' }, key = q.id, onClick = select } (
                    r 'h3' { className = 'name' } (
                      [
                        i <- [1..(q.level)]
                        r 'span' { className = 'level-indent' }
                      ]
                      q.name
                    )
                    r 'div' { className 'buttons' } (
                      r 'button' {
                        className = 'remove-query remove'
                        onClick = remove
                        dangerouslySetInnerHTML = {
                          __html = '&cross;'
                        }
                      }
                    )
                  )
                ]

              draggable {
                itemMoved = itemMoved
                render = render
              }

            if (self.state.queries.length == 0)
              r 'button' { onClick = self.addQuery } 'Add Query'
          )
      )

      r 'div' { className = 'edit-block' } (
        r 'div' { className = 'buttons' } (
          if (@not self.state.block.id)
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
            r 'input' { id = 'block_name', type = 'text', value = self.state.block.name, onChange = self.nameChanged }
          )
        )
        if (self.state.selectedQuery)
          [
            r 'hr' {}
            queryComponent {
              http = self.props.http
              query = self.state.selectedQuery
              updateQuery = self.updateQuery
              createQuery = self.createQuery
              insertQueryBefore = self.insertQueryBefore
              insertQueryAfter = self.insertQueryAfter
            }
          ]
      )
    )
})
