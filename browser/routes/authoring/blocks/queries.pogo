React = require 'react'
ReactRouter = require 'react-router'
State = ReactRouter.State
Link = React.createFactory(ReactRouter.Link)
r = React.createElement

module.exports = React.createFactory(React.createClass {
  mixins = [State]

  getInitialState() =
    { loaded = false, name = '', queries = [] }

  componentDidMount() =
    path = '/api/blocks/' + self.getParams().id
    self.props.http.get(path).done @(response)
      self.setState {
        id = response.id
        loaded = true
        name = response.name
      }

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
          r 'label' {} 'TODO: queries'
      )
    else
      r 'div' {} 'Loading...'
})
