React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
r = React.createElement

module.exports = React.createFactory(React.createClass {
  getInitialState() =
    { name = '' }

  render() =
    r 'form' { onSubmit = self.submitForm } (
      r 'label' { htmlFor = 'block_name' } 'Block Name'
      r 'input' { id = 'block_name', type = 'text' } (self.state.name)
      r 'input' { type = 'submit', value = 'Create Block' }
    )

  submitForm(e) =
    e.preventDefault()
    response = self.props.http.post('/api/blocks') ^!
})
