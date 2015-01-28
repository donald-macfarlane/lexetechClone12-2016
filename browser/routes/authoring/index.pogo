React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
RouteHandler = React.createFactory(ReactRouter.RouteHandler)
r = React.createElement
blockComponent = require './blocks/block'
State = ReactRouter.State

module.exports = React.createFactory(React.createClass {
  mixins = [State]

  getInitialState() =
    { blocks = [] }

  componentDidMount() =
    path = '/api/blocks'
    self.props.http.get(path).done @(response)
      if (self.isMounted())
        self.setState {
          loaded = true
          blocks = response
        }

  render() =
    r 'div' { className = 'authoring-index edit-lexicon'} (
      r 'div' { className = 'authoring-menu' } (
        Link { to = 'create_block' } 'New Block'
      )
      blockComponent {
        http = self.props.http
      }
    )
})
