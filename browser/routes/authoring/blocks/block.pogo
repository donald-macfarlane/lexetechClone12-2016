React = require 'react'
ReactRouter = require 'react-router'
State = ReactRouter.State
Link = React.createFactory(ReactRouter.Link)
r = React.createElement
Navigation = ReactRouter.Navigation
_ = require 'underscore'

module.exports = React.createFactory(React.createClass {
  mixins = [State, Navigation]

  getInitialState() =
    { block = { name = '', queries = [] } }

  componentDidMount() =
    if (self.getParams().blockId)
      q = self.queries()
      b = self.block()

      b!.queries = q!

      self.state.block = b!
      self.setState { block = b! }

  queries() =
    path = "/api/blocks/#(self.getParams().blockId)/queries"
    self.state.block.queries = self.props.http.get(path)!
    
  block() =
    path = '/api/blocks/' + self.getParams().blockId
    self.props.http.get(path)!
    
  addQuery () =
    self.transitionTo('create_query', { blockId = self.state.block.id })

  nameChanged(e) =
    self.state.block.name = e.target.value
    self.update()

  update() =
    self.setState { block = self.state.block, dirty = true }

  save() =
    self.props.http.post("/api/blocks/#(self.state.block.id)", _.omit(self.state.block, 'queries'))!
    self.cancel()

  create() =
    self.props.http.post("/api/blocks", _.omit(self.state.block, 'queries'))!
    self.cancel()

  cancel() =
    self.transitionTo('authoring')

  render() =
    r 'div' { className = 'edit-block' } (
      r 'div' { className = 'buttons' } (
        if (@not self.state.block.id)
          r 'button' { className = 'create', onClick = self.create } 'Create'
        else if (self.state.dirty)
          r 'button' { className = 'save', onClick = self.save } 'Save'

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

            if (self.state.block.queries.length == 0)
              r 'label' {} 'This block has no queries'
            else
              r 'ol' {} [
                q <- self.state.block.queries

                remove () =
                  self.state.block.queries = _.without(self.state.block.queries, q)
                  self.props.http.delete ("/api/blocks/#(self.getParams().blockId)/queries/#(q.id)")!
                  self.block.queries = self.props.http.get "/api/blocks/#(self.getParams().blockId)/queries"!
                  self.setState { block = self.state.block }

                r 'li' {} (
                  r 'h3' { className = 'name' } (
                    Link { to = 'query', params = { blockId = self.state.block.id, queryId = q.id } } (q.name)
                  )
                  r 'p' { className = 'text' } (q.text)
                  r 'button' { className = 'remove-query', onClick = remove } 'Remove'
                )
              ]

            r 'button' { onClick = self.addQuery } 'Add Query'
          )
      )

      r 'div' {key = 'json'} (
        r 'pre' ({}, r 'code' ('json', JSON.stringify(self.state.block, nil, 2)))
      )
    )
})
