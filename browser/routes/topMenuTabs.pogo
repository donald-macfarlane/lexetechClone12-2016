React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
r = React.createElement

module.exports = React.createFactory(React.createClass {
  render() =
    if (self.props.user)
      r 'div' { className = 'tabs' } (
        Link { to = 'reports' } 'Reports'
        Link { to = 'authoring' } 'Authoring'
      )
    else
      r 'div' { className = 'tabs' }
})
