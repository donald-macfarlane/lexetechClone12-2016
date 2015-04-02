React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
RouteHandler = React.createFactory(ReactRouter.RouteHandler)
r = React.createElement
blockComponent = require './blocks/block'
State = ReactRouter.State

module.exports = React.createClass {
  mixins = [State]

  render() =
    r 'div' { className = 'authoring-index edit-lexicon'} (
      React.createElement(blockComponent, {
        http = self.props.http
      })
    )
}
