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
    loadPredicants() =
      self.setState {
        predicants = self.props.http.get('/api/predicants')!
      }

    loadBlocks() =
      self.setState {
        blocks = _.indexBy(self.props.http.get('/api/blocks')!, 'id')
      }

    loadPredicants()
    loadBlocks()

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

  renderActions(actions) =
    r 'div' {} (
      r 'ol' {} (
        [
          action <- actions
          self.renderAction(action)
        ]
      )
    )

  renderAction(action) =
    renderAction = {
      setBlocks(action) =
        r 'li' { className = 'action-set-blocks' } (
          r 'h4' {} 'Set Blocks'
          if (self.state.blocks)
            addBlock(block) =
              action.arguments.push(block.id)
              self.update()

            removeBlock(block) =
              remove (block.id) from (action.arguments)
              self.update()

            renderBlockText(b) =
              if (b.name)
                "#(b.id): #(b.name)"
              else
                b.id

            [
              r 'ol' {} (
                [
                  id <- action.arguments

                  b = self.state.blocks.(id)
                  remove() = removeBlock(b)

                  r 'li' {} (
                    r 'span' {} (renderBlockText(b))
                    r 'button' {
                      className = 'remove-block remove'
                      onClick = remove
                      dangerouslySetInnerHTML = {
                        __html = '&cross;'
                      }
                    }
                  )
                ]
              )
              itemSelect({
                onAdd = addBlock
                onRemove = removeBlock
                selectedItems = action.arguments
                items = self.state.blocks
                renderItemText = renderBlockText
                placeholder = 'add block'
              })
            ]

          ...
        )
    }.(action.name)

    if (renderAction)
      renderAction.call(self, action)

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
              className = 'remove-predicant remove'
              onClick = remove
              dangerouslySetInnerHTML = {
                __html = '&cross;'
              }
            }
          )
        ]

        itemSelect({
          onAdd = addPredicant
          onRemove = removePredicant
          selectedItems = predicants
          items = self.state.predicants
          placeholder = 'add predicant'
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

  numberInput(model, field) =
    r 'input' {
      type = 'number'
      onChange = self.bind(model, field, Number)
      value = model.(field)
      onFocus(ev) =
        $(ev.target).on 'mousewheel.disableScroll' @(ev)
          ev.preventDefault()

      onBlur(ev) =
        $(ev.target).off 'mousewheel.disableScroll'
    }

  cancel() =
    self.transitionTo('block', { blockId = self.getParams().blockId })

  render() =
    r 'div' { className = 'edit-query' } (
      r 'div' { className = 'buttons' } (

        if (self.state.dirty)
          [
            if (self.props.query.id)
              [
                r 'button' { className = 'insert-query-before', onClick = self.insertBefore } 'Insert Before'
                r 'button' { className = 'insert-query-after', onClick = self.insertAfter } 'Insert After'
                r 'button' { className = 'save', onClick = self.save } 'Save'
              ]
            else
              [
                r 'button' { className = 'create', onClick = self.create } 'Create'
              ]

            ...
            r 'button' { className = 'cancel', onClick = self.cancel } 'Cancel'
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
          self.numberInput(self.props.query, 'level')
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
                  block
                    select() =
                      self.setState { selectedResponse = response }

                    deselect() =
                      self.setState { selectedResponse = nil }

                    [
                      if (self.state.selectedResponse == response)
                        r 'div' { className = 'buttons top' } (
                          r 'button' { className = 'close', onClick = deselect } 'Close'
                        )

                      r 'ul' {} (
                        r 'li' { className = 'selector' } (
                          r 'label' {} 'Selector'
                          r 'textarea' { onChange = self.bind(response, 'text'), value = response.text, onFocus = select }
                        )
                        if (self.state.selectedResponse == response)
                          [
                            r 'li' {} (
                              r 'label' {} 'Set Level'
                              self.numberInput(response, 'setLevel')
                            )
                            r 'li' {} (
                              r 'label' {} 'Style 1'
                              r 'textarea' { onChange = self.bind(response.styles, '1'), value = response.styles.('1') }
                            )
                            r 'li' {} (
                              r 'label' {} 'Style 2'
                              r 'textarea' { onChange = self.bind(response.styles, '2'), value = response.styles.('2') }
                            )
                            r 'li' { className = 'actions' } (
                              r 'label' {} 'Actions'
                              self.renderActions(response.actions)
                            )
                            r 'li' {} (
                              r 'label' {} 'Predicants'
                              self.renderPredicants(response.predicants)
                            )
                          ]
                      )
                      r 'div' { className = 'buttons' } (
                        r 'button' { className = 'remove-response', onClick = remove } 'Remove'
                      )
                    ]
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
    )
})

itemSelect = React.createFactory(React.createClass {
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
    (p) matchesSearch (search) =
      if (self.search == '')
        true
      else
        terms = _.compact(search.toLowerCase().split r/ +/)

        _.all(terms) @(t)
          p.name.toLowerCase().indexOf(t) >= 0

    selected = index (self.props.selectedItems)

    matchingItems = [
      k <- Object.keys(self.props.items)
      p = self.props.items.(k)
      (p) matchesSearch (self.state.search)
      p
    ]

    selectItem(p) =
      if (selected.(p.id))
        self.props.onRemove(p)
      else
        self.props.onAdd(p)

    searchKeyDown(ev) =
      if (ev.keyCode == 13)
        selectItem(matchingItems.0)

    r 'div' { className = 'item-select', onMouseDown = self.activate, onMouseUp = self.disactivate, onBlur = self.blur, onFocus = self.focus } (
      r 'input' { type = 'text', placeholder = self.props.placeholder, onChange = self.searchChange, onKeyDown = searchKeyDown, value = self.state.search }

      r 'div' { className = 'select-list' } (
        r 'ol' {className = if (self.state.show) @{ 'show' } else @{''}} [
          p <- matchingItems

          select() =
            selectItem(p)

          text =
            if (self.props.renderItemText)
              self.props.renderItemText(p)
            else
              p.name
      
          r 'li' { onClick = select } (
            r 'span' {} (text)

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
