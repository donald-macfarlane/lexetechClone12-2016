React = require 'react'
r = React.createElement
ReactRouter = require 'react-router'
Navigation = ReactRouter.Navigation
_ = require 'underscore'
draggable = require '../draggable'
moveItemInFromTo = require '../moveItemInFromTo'

module.exports = React.createFactory(React.createClass {
  mixins = [ReactRouter.State, Navigation]

  getInitialState() =
    { query = module.exports.create(), predicants = [], lastResponseId = 0 }

  componentDidMount() =
    predicants = self.props.http.get('/api/predicants')

    self.setState {
      predicants = predicants!
    }

  bind(model, field, transform) =
    @(ev)
      if (transform)
        model.(field) = transform(ev.target.value)
      else
        model.(field) = ev.target.value

      self.update()

  addResponse() =
    id = ++self.state.lastResponseId
    response = {
      text = ''
      predicants = []
      styles = {
        'one' = ''
        'two' = ''
      }
      actions = []
      id = id
    }
    self.props.query.responses.push (response)

    self.update()
    self.setState { selectedResponse = response }

  update(dirty = true) =
    self.setState { dirty = dirty }

  renderPredicants(predicants) =
    addPredicant(predicant) =
      predicants.push(predicant.id)
      self.update()

    removePredicant(predicant) =
      remove (predicant.id) from (predicants)
      self.update()

    if (Object.keys(self.state.predicants).length > 0)
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
    self.props.updateQuery(self.props.query)!
    self.update(dirty = false)

  create() =
    self.props.createQuery(self.props.query)!
    self.update(dirty = false)

  insertBefore() =
    self.props.insertQueryBefore(self.props.query)!
    self.update(dirty = false)

  insertAfter() =
    self.props.insertQueryAfter(self.props.query)!
    self.update(dirty = false)

  cancel() =
    self.transitionTo('block', { blockId = self.getParams().blockId })

  render() =
    r 'div' { className = 'edit-query' } (
      r 'div' { className = 'buttons' } (

        if (self.state.dirty)
          [
            r 'button' { className = 'cancel', onClick = self.cancel } 'Cancel'

            if (self.props.query.id)
              [
                r 'button' { className = 'save', onClick = self.save } 'Save'
                r 'button' { className = 'insert-query-before', onClick = self.insertBefore } 'Insert Before'
                r 'button' { className = 'insert-query-after', onClick = self.insertAfter } 'Insert After'
              ]
            else
              [
                r 'button' { className = 'create', onClick = self.create } 'Create'
              ]

            ...
          ]
        else
          r 'button' { className = 'cancel', onClick = self.cancel } 'Close'
      )
      r 'h2' {} 'Query'
      r 'ul' {} (
        r 'li' {key = 'name'} (
          r 'label' {} 'Name'
          r 'input' {type = 'text', onChange = self.bind(self.props.query, 'name'), value = self.props.query.name }
        )
        r 'li' {key = 'qtext'} (
          r 'label' {} 'Question'
          r 'textarea' { onChange = self.bind(self.props.query, 'text') } ( self.props.query.text )
        )
        r 'li' {key = 'level'} (
          r 'label' {} 'Level'
          r 'input' { type = 'number', onChange = self.bind(self.props.query, 'level', Number), value = self.props.query.level }
        )

        r 'li' {} (
          r 'label' {} 'Predicants'
          self.renderPredicants(self.props.query.predicants)
        )

        r 'li' { className = 'responses' } (
          r 'h3' {} 'Responses'
          block
            render() =
              r 'ol' {} [
                response <- self.props.query.responses

                remove () =
                  self.props.query.responses = _.without(self.props.query.responses, response)
                  self.update()

                r 'li' { key = response.id } (
                  if (self.state.selectedResponse == response)
                    [
                      r 'ul' {} (
                        r 'li' {} (
                          r 'label' {} 'Selector'
                          r 'textarea' { onChange = self.bind(response, 'text'), value = response.text }
                        )
                        r 'li' {} (
                          r 'label' {} 'Style 1'
                          r 'textarea' { onChange = self.bind(response.styles, 'one'), value = response.styles.one }
                        )
                        r 'li' {} (
                          r 'label' {} 'Style 2'
                          r 'textarea' { onChange = self.bind(response.styles, 'two'), value = response.styles.two }
                        )
                        r 'li' {} (
                          r 'label' {} 'Predicants'
                          self.renderPredicants(response.predicants)
                        )
                      )
                      r 'button' { className = 'remove-response', onClick = remove } 'Remove'
                    ]
                  else
                    select() =
                      self.setState { selectedResponse = response }

                    r 'div' { onClick = select } (response.text)
                )
              ]

            itemMoved(from, to) =
              moveItemIn (self.props.query.responses) from (from) to (to)
              self.update()

            draggable {
              itemMoved = itemMoved
              render = render
            }

          r 'button' { className = 'add', onClick = self.addResponse } 'Add Response'
        )
      )

      r 'div' {key = 'json'} (
        r 'pre' ({}, r 'code' ('json', JSON.stringify(self.props.query, nil, 2)))
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

block(b) =
  b()

remove (item) from (array) =
  i = array.indexOf(item)
  if (i >= 0)
    array.splice(i, 1)

index(array) =
  obj = {}

  for (n = 0, n < array.length, ++n)
    obj.(array.(n)) = true

  obj

module.exports.create(obj) =
  _.extend {
    responses = []
    predicants = []
    level = 0
  } (obj)
