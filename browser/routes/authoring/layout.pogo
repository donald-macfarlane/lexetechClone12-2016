React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
RouteHandler = React.createFactory(ReactRouter.RouteHandler)
r = React.createElement

module.exports = React.createFactory(React.createClass {
  render() =
    r 'div' { className = 'authoring' } (
      r 'h1' {} 'Authoring'
      RouteHandler.call(self, self.props)
    )
})
