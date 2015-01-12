React = require 'react'
r = React.createElement
ReactRouter = require 'react-router'
Navigation = ReactRouter.Navigation
_ = require 'underscore'

module.exports = React.createFactory(React.createClass {
  getInitialState() =
    { query = {predicants = [], responses = []}, predicants = [] }

  componentDidMount() =
    self.setState {
      predicants = self.props.http.get('/api/predicants')!
    }

  bind(model, field) =
    @(ev)
      model.(field) = ev.target.value
      self.setState(self.state)

  addResponse() =
    self.state.query.responses.push {
      text = ''
      predicants = []
      notes = ''
      actions = []
    }

    self.setState {query = self.state.query}

  renderPredicants(predicants) =
    addPredicant(predicant) =
      predicants.push(predicant.id)
      self.setState({query = self.state.query})

    removePredicant(predicant) =
      remove (predicant.id) from (predicants)
      self.setState({query = self.state.query})

    r 'div' { className = 'edit-query' } (
      r 'ol' { className = 'predicants' } [
        id <- predicants
        p = self.state.predicants.(id)

        remove() = removePredicant(p)

        r 'li' {} (
          r 'span' {} (p.name)
          r 'button' {
            className = 'remove'
            onClick = remove
            dangerouslySetInnerHTML = {
              __html = '&cross;'
            }
          }
        )
      ]

      predicantSelect({
        onAddPredicant = addPredicant
        onRemovePredicant = removePredicant
        selectedPredicants = predicants
        predicants = self.state.predicants
      })
    )

  render() =
    r 'div' {} 'create query' (
      r 'div' {key = 'name'} (
        r 'label' {} 'Name'
        r 'input' {type = 'text', onChange = self.bind(self.state.query, 'name'), value = self.state.query.name }
      )
      r 'div' {key = 'qtext'} (
        r 'label' {} 'QText'
        r 'input' {type = 'text', onChange = self.bind(self.state.query, 'text'), value = self.state.query.name }
      )

      self.renderPredicants(self.state.query.predicants)

      r 'ol' {} [
        response <- self.state.query.responses
        r 'li' {} (
          r 'div' {} (
            r 'label' {} 'RText'
            r 'input' { type = 'text', onChange = self.bind(response, 'text'), value = self.state.query.name }
          )
          r 'div' {} (
            r 'label' {} 'Notes'
            r 'input' { type = 'text', onChange = self.bind(response, 'notes'), value = self.state.query.notes }
          )
          self.renderPredicants(response.predicants)
        )
      ]

      r 'button' { onClick = self.addResponse } 'Add'

      r 'div' {key = 'json'} (
        r 'pre' ({}, r 'code' ('json', JSON.stringify(self.state.query, nil, 2)))
      )
    )
})

predicantSelect = React.createFactory(React.createClass {
  getInitialState () = { search = '', show = false }
  searchChange(ev) =
    self.setState {
      search = ev.target.value
    }

  focus() =
    self.setState {
      show = true
    }

  blur(ev) =
    if (@not self.state.activated)
      self.setState {
        show = false
      }
    else
      ev.target.focus()

  activate() =
    self.setState {
      activated = true
    }

  disactivate() =
    self.setState {
      activated = false
    }

  render() =
    predicant (p) matchesSearch (search) =
      if (self.search == '')
        true
      else
        terms = _.compact(search.toLowerCase().split r/ +/)

        _.all(terms) @(t)
          p.name.toLowerCase().indexOf(t) >= 0

    selected = index (self.props.selectedPredicants)
    r 'div' { className = 'predicant-select', onMouseDown = self.activate, onMouseUp = self.disactivate, onBlur = self.blur, onFocus = self.focus } (
      r 'input' { type = 'text', placeholder = 'add predicate', onChange = self.searchChange, value = self.state.search }

      r 'div' { className = 'select-list' } (
        r 'ol' {className = if (self.state.show) @{ 'show' } else @{''}} [
          k <- Object.keys(self.props.predicants)
          p = self.props.predicants.(k)

          predicant (p) matchesSearch (self.state.search)

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
