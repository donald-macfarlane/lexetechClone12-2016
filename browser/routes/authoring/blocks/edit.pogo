React = require 'react'
ReactRouter = require 'react-router'
Navigation = ReactRouter.Navigation
Link = React.createFactory(ReactRouter.Link)
r = React.createElement

module.exports = React.createFactory(React.createClass {
  mixins = [Navigation]

  getInitialState() =
    { name = '' }

  render() =
    r 'div' {} (
      r 'h1' {} 'Edit Block'
    )
})
