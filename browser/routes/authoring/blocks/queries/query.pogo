React = require 'react'
r = React.createElement
ReactRouter = require 'react-router'
Navigation = ReactRouter.Navigation
_ = require 'underscore'
sortable = require '../sortable'
moveItemInFromTo = require '../moveItemInFromTo'
blockName = require '../blockName'

reactBootstrap = require 'react-bootstrap'
DropdownButton = reactBootstrap.DropdownButton
MenuItem = reactBootstrap.MenuItem

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
        'style1' = ''
        'style2' = ''
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
    addAction(action) =
      actions.push(action)

      self.update()

    removeAction(action) =
      remove (action) from (actions)
      self.update()

    addActionClick(createAction) =
      handler (ev) =
        action = createAction()
        addAction (action)
        ev.preventDefault()
      
    r 'div' {} (
      r 'ol' {} (
        [
          action <- actions
          remove() = removeAction(action)
          self.renderAction(action, remove)
        ]
      )
      DropdownButton {title = 'Add Action'} (
        MenuItem { onClick = addActionClick @{ { name = 'setBlocks', arguments = [] } } } ('Set Block')
        MenuItem { onClick = addActionClick @{ { name = 'addBlocks', arguments = [] } } } ('Add Block')
        MenuItem { onClick = addActionClick @{ { name = 'email', arguments = [] } } } ('Email')
        MenuItem { onClick = addActionClick @{ { name = 'repeatLexeme', arguments = [] } } } ('Repeat')
        MenuItem { onClick = addActionClick @{ { name = 'setVariable', arguments = ['', ''] } } } ('Set Variable')
        MenuItem { onClick = addActionClick @{ { name = 'suppressPunctuation', arguments = [] } } } ('Suppress Punctuation')
        MenuItem { onClick = addActionClick @{ { name = 'loadFromFile', arguments = [] } } } ('Load from File')
        MenuItem { onClick = addActionClick @{ { name = 'setGender', arguments = [] } } } ('Set Gender')
      )
    )

  renderAction(action, removeAction) =
    removeButton () = r 'div' { className = 'buttons' } (
      r 'button' { className = 'remove-action', onClick = removeAction } 'Remove'
    )

    blocks(name, class) =
      r 'li' { className = class} (
        r 'h4' {} (name)
        if (self.state.blocks)
          addBlock(block) =
            action.arguments.push(block.id)
            self.update()

          removeBlock(block) =
            remove (block.id) from (action.arguments)
            self.update()

          renderArguments() =
            r 'ol' {} (
              [
                id <- action.arguments

                b = self.state.blocks.(id)
                remove() = removeBlock(b)

                r 'li' {} (
                  r 'span' {} (blockName(b))
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

          itemMoved(from, to) =
            moveItemIn (action.arguments) from (from) to (to)
            self.update()

          [
            sortable {
              itemMoved = itemMoved
              render = renderArguments
            }
            itemSelect({
              onAdd = addBlock
              onRemove = removeBlock
              selectedItems = action.arguments
              items = self.state.blocks
              renderItemText = blockName
              placeholder = 'add block'
            })
          ]

        ...

        removeButton()
      )

    renderAction = {
      setBlocks(action) = blocks('Set Blocks', 'action-set-blocks')
      addBlocks(action) = blocks('Add Blocks', 'action-add-blocks')
      setVariable(action) =
        r 'li' {} (
          r 'h4' {} 'Set Variable'
          r 'ul' {} (
            r 'li' {} (
              r 'label' {} 'Name'
              r 'input' { type = 'text', onChange = self.bind(action.arguments, 0), value = action.arguments.0 }
            )
            r 'li' {} (
              r 'label' {} 'Value'
              r 'input' { type = 'text', onChange = self.bind(action.arguments, 1), value = action.arguments.1 }
            )
          )
          removeButton()
        )

      email(action) =
        r 'li' {} (
          r 'h4' {} 'Send Email'
          r 'ul' {} (
            r 'li' {} (
              r 'label' {} 'Email Address'
              r 'input' { type = 'text', onChange = self.bind(action.arguments, 0), value = action.arguments.0 }
            )
          )
          removeButton()
        )

      repeatLexeme(action) =
        r 'li' {} (
          r 'h4' {} 'Repeat Lexeme'
          removeButton()
        )

      suppressPunctuation(action) =
        r 'li' {} (
          r 'h4' {} 'Suppress Punctuation'
          removeButton()
        )

      setGender(action) =
        r 'li' { className 'action-set-gender' } (
          r 'h4' {} 'Set Gender'
          r 'ul' {} (
            r 'li' {} (
              r 'form' {} (
                r 'label' {} ('Male', r 'input' { type = 'radio', name = 'gender' })
                r 'label' {} ('Female', r 'input' { type = 'radio', name = 'gender' })
              )
            )
          )
          removeButton()
        )

      loadFromFile(action) =
        r 'li' {} (
          r 'h4' {} 'Load from File'
          removeButton()
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
        r 'li' {key = 'name', className = 'name' } (
          r 'label' {} 'Name'
          r 'input' {type = 'text', onChange = self.bind(self.props.query, 'name'), value = self.props.query.name }
        )
        r 'li' {key = 'qtext', className = 'question' } (
          r 'label' {} 'Question'
          r 'textarea' { onChange = self.bind(self.props.query, 'text') } ( self.props.query.text )
        )
        r 'li' {key = 'level', className = 'level' } (
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
                            r 'li' { className = 'set-level' } (
                              r 'label' {} 'Set Level'
                              self.numberInput(response, 'setLevel')
                            )
                            r 'li' { className = 'style1' } (
                              r 'label' {} 'Style 1'
                              r 'textarea' { onChange = self.bind(response.styles, 'style1'), value = response.styles.('1') }
                            )
                            r 'li' { className = 'style2' } (
                              r 'label' {} 'Style 2'
                              r 'textarea' { onChange = self.bind(response.styles, 'style2'), value = response.styles.('2') }
                            )
                            r 'li' { className = 'actions' } (
                              r 'label' {} 'Actions'
                              self.renderActions(response.actions)
                            )
                            r 'li' { className = 'predicants' } (
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

            sortable {
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
    level = 1
  } (obj)
