React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
RouteHandler = React.createFactory(ReactRouter.RouteHandler)
r = React.createElement

module.exports = React.createFactory(React.createClass {
  render() =
    r 'div' { className = 'authoring-menu' } (
      Link { to = 'new_block' } 'New Block'
    )
})
