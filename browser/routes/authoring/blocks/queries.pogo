React = require 'react'
ReactRouter = require 'react-router'
State = ReactRouter.State
Link = React.createFactory(ReactRouter.Link)
r = React.createElement
Navigation = ReactRouter.Navigation

module.exports = React.createFactory(React.createClass {
  mixins = [State, Navigation]

  getInitialState() =
    { loaded = false, name = '', queries = [] }

  componentDidMount() =
    self.loadQueries()
    self.loadBlock()

  loadQueries() =
    path = "/api/blocks/#(self.getParams().id)/queries"
    queries = self.props.http.get(path)!

    self.setState {
      queries = queries
    }
    
  loadBlock() =
    path = '/api/blocks/' + self.getParams().id
    response = self.props.http.get(path)!

    self.setState {
      id = response.id
      loaded = true
      name = response.name
    }
    
  addQuery () =
    self.transitionTo('new_query', { id = self.state.id })

  render() =
    if (self.state.loaded)
      r 'div' {} (
        r 'div' { className = 'authoring-menu' } (
          Link { to = 'edit_block', params = { id = self.state.id } } 'Edit Block'
        )
        r 'h1' {} (self.state.name)
        r 'h2' {} 'Queries'
        if (self.state.queries.length == 0)
          r 'label' {} 'This block has no queries'
        else
          r 'ol' {} [
            q <- self.state.queries
            r 'li' (r 'pre' (r 'code' (JSON.stringify(q, nil, 2))))
          ]

        r 'button' { onClick = self.addQuery } 'Add'
      )
    else
      r 'div' {} 'Loading...'
})
