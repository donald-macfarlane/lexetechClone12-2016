React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
r = React.createElement

module.exports = React.createClass {
  render() =
    if (self.props.user)
      r 'div' { className = 'tabs' } (
        r 'a' { href = '/' } 'Report'
        Link { to = 'authoring' } 'Authoring'
      )
    else
      r 'div' { className = 'tabs' }
}
