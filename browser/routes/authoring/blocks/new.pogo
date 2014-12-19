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
      r 'h1' {} 'New Block'
      r 'form' { onSubmit = self.submitForm } (
        r 'label' { htmlFor = 'block_name' } 'Block Name'
        r 'input' { id = 'block_name', type = 'text', onChange = self.nameChanged } (self.state.name)
        r 'input' { type = 'submit', value = 'Create Block' }
      )
    )

  nameChanged(e) =
    self.state.name = e.target.value

  submitForm(e) =
    e.preventDefault()
    self.props.http.post('/api/blocks', { name = self.state.name }).done (self.redirectToBlock)

  redirectToBlock (response) =
    self.transitionTo('block', id: response.block.id)
})
