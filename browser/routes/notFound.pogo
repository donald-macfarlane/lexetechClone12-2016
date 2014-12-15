React = require 'react'
r = React.createElement

module.exports = React.createFactory(React.createClass {
  render() =
    r 'div' { className = 'not-found-page' } 'Not Found :('
})