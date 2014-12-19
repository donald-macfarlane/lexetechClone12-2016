React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
r = React.createElement

module.exports = React.createFactory(React.createClass {
  mixins = [ReactRouter.State]

  getInitialState() =
    { name = '' }

  componentDidMount() =
    path = '/api/blocks/' + self.getParams().id
    self.props.http.get(path).done @(response)
      self.setState {
        id = response.id
        loaded = true
        name = response.name
      }

  render() =
    if (self.state.loaded)
      r 'div' {} (
        r 'h1' {} "Edit Block: #(self.state.name)"
        r 'form' { onSubmit = self.submitForm } (
          r 'label' { htmlFor = 'block_name' } 'Name'
          r 'input' { id = 'block_name', type = 'text', value = self.state.name, onChange = self.nameChanged }
          r 'input' { type = 'submit', value = 'Update Block' }
        )
      )
    else
      r 'div'

  nameChanged(e) =
    self.setState { name = e.target.value }

  submitForm(e) =
    e.preventDefault()
    path = '/api/blocks/' + self.getParams().id
    self.props.http.post(path, { name = self.state.name }).done (self.redirectToBlock)

  redirectToBlock (response) =
    self.transitionTo('block', id: response.block.id)
})
