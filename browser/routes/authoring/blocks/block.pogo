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
        r 'h2' {} ('Block ', self.state.block.name)
        r 'ul' {} (
          r 'li' {} (
            r 'label' { htmlFor = 'block_name' } 'Name'
            r 'input' { id = 'block_name', type = 'text', value = self.state.block.name, onChange = self.nameChanged }
          )

          if (self.state.block.id)
            r 'li' { className = 'queries' } (
              r 'h3' {} 'Queries'

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
                        r 'button' { className = 'remove-query', onClick = remove } 'Remove'
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

        r 'div' {key = 'json'} (
          r 'pre' ({}, r 'code' ('json', JSON.stringify(self.state, nil, 2)))
        )
      )
      if (self.state.selectedQuery)
        queryComponent {
          http = self.props.http
          query = self.state.selectedQuery
          updateQuery = self.updateQuery
          createQuery = self.createQuery
          insertQueryBefore = self.insertQueryBefore
          insertQueryAfter = self.insertQueryAfter
        }
    )
})
