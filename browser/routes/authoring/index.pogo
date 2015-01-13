React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
RouteHandler = React.createFactory(ReactRouter.RouteHandler)
r = React.createElement

module.exports = React.createFactory(React.createClass {
  getInitialState() =
    { blocks = [] }

  componentDidMount() =
    path = '/api/blocks'
    self.props.http.get(path).done @(response)
      self.setState {
        loaded = true
        blocks = response
      }

  render() =
    r 'div' { className = 'authoring-index'} (
      r 'div' { className = 'authoring-menu' } (
        Link { to = 'create_block' } 'New Block'
      )
      r 'h1' {} 'Blocks'
      r 'ul' { className = 'block-list' } (
        [
          block <- self.state.blocks
          r 'li' {} (Link { to = 'block', params = { blockId = block.id } } (
            r 'span' { className = 'block-id' } (block.id)
            r 'span' { className = 'block-name' } (block.name)
          ))
        ]
        ...
      )
    )
})
