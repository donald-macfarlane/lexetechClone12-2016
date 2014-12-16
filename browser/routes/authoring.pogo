React = require 'react'
r = React.createElement

module.exports = React.createFactory(React.createClass {
  render() =
    r 'button' {} 'New Block'
})
