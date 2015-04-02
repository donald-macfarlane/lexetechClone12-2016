React = require 'react'
Draggable = require '../../../draggable'

module.exports = React.createClass {
  mixins = [Draggable()]

  itemDragged(from, to) =
    self.props.itemMoved(from, to)

  render() =
    x = self.props.render()
    for each @(child) in (x.props.children)
      child.props.draggable = true

    x
}
