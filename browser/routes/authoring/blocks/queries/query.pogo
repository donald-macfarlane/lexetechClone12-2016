React = require 'react'
r = React.createElement
ReactRouter = require 'react-router'
Navigation = ReactRouter.Navigation
_ = require 'underscore'

module.exports = React.createFactory(React.createClass {
  mixins = [ReactRouter.State, Navigation]

  getInitialState() =
    { query = {predicants = [], responses = []}, predicants = [], lastResponseId = 0 }

  componentDidMount() =
    query =
      if (self.getParams().queryId != nil)
        self.query()
      else
        self.state.query

    predicants = self.props.http.get('/api/predicants')

    self.setState {
      predicants = predicants!
      query = query!
    }

  query() =
    query = self.props.http.get("/api/blocks/#(self.getParams().blockId)/queries/#(self.getParams().queryId)")!
    query.predicants = query.predicants @or []
    query.actions = query.actions @or []
    query.responses = query.responses @or []
    query

  bind(model, field) =
    @(ev)
      model.(field) = ev.target.value
      self.setState(self.state)

  addResponse() =
    id = ++self.state.lastResponseId
    self.state.query.responses.push {
      text = ''
      predicants = []
      notes = ''
      actions = []
      id = id
    }

    self.setState {query = self.state.query}

  renderPredicants(predicants) =
    addPredicant(predicant) =
      predicants.push(predicant.id)
      self.setState({query = self.state.query})

    removePredicant(predicant) =
      remove (predicant.id) from (predicants)
      self.setState({query = self.state.query})

    r 'div' { className = 'predicants' } (
      r 'ol' {} [
        id <- predicants
        p = self.state.predicants.(id)

        remove() = removePredicant(p)

        r 'li' {} (
          r 'span' {} (p.name)
          r 'button' {
            className = 'remove-predicant'
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

  save() =
    self.props.http.post("/api/blocks/#(self.getParams().blockId)/queries/#(self.getParams().queryId)", self.state.query)!
    self.cancel()

  create() =
    self.props.http.post("/api/blocks/#(self.getParams().blockId)/queries", self.state.query)!
    self.cancel()

  cancel() =
    self.transitionTo('block', { blockId = self.getParams().blockId })

  render() =
    r 'div' { className = 'edit-query' } (
      r 'div' { className = 'buttons' } (
        if (self.state.query.id)
          r 'button' { className = 'save', onClick = self.save } 'Save'
        else
          r 'button' { className = 'create', onClick = self.create } 'Create'

        r 'button' { className = 'cancel', onClick = self.cancel } 'Cancel'
      )
      r 'h2' {} 'Query'
      r 'ul' {} (
        r 'li' {key = 'name'} (
          r 'label' {} 'Name'
          r 'input' {type = 'text', onChange = self.bind(self.state.query, 'name'), value = self.state.query.name }
        )
        r 'li' {key = 'qtext'} (
          r 'label' {} 'QText'
          r 'textarea' { onChange = self.bind(self.state.query, 'text') } ( self.state.query.text )
        )

        r 'li' {} (
          r 'label' {} 'Predicants'
          self.renderPredicants(self.state.query.predicants)
        )

        r 'li' { className = 'responses' } (
          r 'h3' {} 'Responses'
          r 'ol' {} [
            response <- self.state.query.responses

            remove () =
              self.state.query = _.without(self.state.query.responses, response)
              self.setState { query = self.state.query }

            r 'li' { key = response.id } (
              r 'ul' {} (
                r 'li' {} (
                  r 'label' {} 'RText'
                  r 'input' { type = 'text', onChange = self.bind(response, 'text'), value = response.name }
                )
                r 'li' {} (
                  r 'label' {} 'Notes'
                  r 'input' { type = 'text', onChange = self.bind(response, 'notes'), value = response.notes }
                )
                r 'li' {} (
                  r 'label' {} 'Predicants'
                  self.renderPredicants(response.predicants)
                )
              )
              r 'button' { className = 'remove-response', onClick = remove } 'Remove'
            )
          ]
          ...
          r 'button' { className = 'add', onClick = self.addResponse } 'Add Response'
        )
      )

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

    matchingPredicants = [
      k <- Object.keys(self.props.predicants)
      p = self.props.predicants.(k)
      predicant (p) matchesSearch (self.state.search)
      p
    ]

    selectPredicant(p) =
      if (selected.(p.id))
        self.props.onRemovePredicant(p)
      else
        self.props.onAddPredicant(p)

    searchKeyDown(ev) =
      if (ev.keyCode == 13)
        selectPredicant(matchingPredicants.0)

    r 'div' { className = 'predicant-select', onMouseDown = self.activate, onMouseUp = self.disactivate, onBlur = self.blur, onFocus = self.focus } (
      r 'input' { type = 'text', placeholder = 'add predicant', onChange = self.searchChange, onKeyDown = searchKeyDown, value = self.state.search }

      r 'div' { className = 'select-list' } (
        r 'ol' {className = if (self.state.show) @{ 'show' } else @{''}} [
          p <- matchingPredicants

          select() =
            selectPredicant(p)
      
          r 'li' { onClick = select } (
            r 'span' {} (p.name)

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
