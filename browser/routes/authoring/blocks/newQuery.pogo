React = require 'react'
r = React.createElement
ReactRouter = require 'react-router'
Navigation = ReactRouter.Navigation

module.exports = React.createFactory(React.createClass {
  getInitialState() =
    { query = {predicants = []}, predicants = [] }

  componentDidMount() =
    self.setState {
      predicants = self.props.http.get('/api/predicants')!
    }

  bind(model, field) =
    @(ev)
      model.(field) = ev.target.value
      self.setState(self.state)

  addPredicant(predicant) =
    self.state.query.predicants.push(predicant.id)
    self.setState({query = self.state.query})

  removePredicant(predicant) =
    remove (predicant.id) from (self.state.query.predicants)
    self.setState({query = self.state.query})

  render() =
    r 'div' {} 'create query' (
      r 'div' {key = 'name'} (
        r 'label' {} 'Name'
        r 'input' {type = 'text', onChange = self.bind(self.state.query, 'name') } (self.state.query.name)
      )
      r 'div' {key = 'qtext'} (
        r 'label' {} 'QText'
        r 'input' {type = 'text', onChange = self.bind(self.state.query, 'text') } (self.state.query.name)
      )

      r 'ol' {} [
        id <- self.state.query.predicants
        p = self.state.predicants.(id)
        r 'li' {} (p.name)
      ]

      predicantSelect({
        onAddPredicant = self.addPredicant
        onRemovePredicant = self.removePredicant
        selectedPredicants = self.state.query.predicants
        predicants = self.state.predicants
      })
      r 'div' {key = 'json'} (
        r 'pre' ({}, r 'code' ('json', JSON.stringify(self.state.query, nil, 2)))
      )
    )
})

predicantSelect = React.createFactory(React.createClass {
  getInitialState () = { search = '' }
  searchChange(ev) =
    self.setState {
      search = ev.target.value
    }

  render() =
    selected = index (self.props.selectedPredicants)
    r 'div' { className = 'predicant-select' } (
      r 'input' { type = 'text', placeholder = 'search', onChange = self.searchChange, value = self.state.search }
      r 'ol' {} [
        k <- Object.keys(self.props.predicants)
        p = self.props.predicants.(k)

        self.state.search == "" @or p.name.indexOf (self.state.search) != -1

        selectPredicant() =
          if (selected.(p.id))
            self.props.onRemovePredicant(p)
          else
            self.props.onAddPredicant(p)
    
        r 'li' { onClick = selectPredicant } (
          r 'span' {} (p.name)
          r 'span' {} (', id ', p.id)

          if (selected.(p.id))
            r 'span' {className = 'selected', dangerouslySetInnerHTML = { __html = '&#x2713;' }}
        )
      ]
    )
})

remove (item) from (array) =
  i = array.indexOf(item)
  if (i >= 0)
    array.splice(i, 1)

index(array) =
  obj = {}

  for (n = 0, n < array.length, ++n)
    obj.(array.(n)) = true

  obj
