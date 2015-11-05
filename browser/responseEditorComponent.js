var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var responseHtmlEditor = require('./responseHtmlEditor');
var stripNbsp = require('./stripNbspBinding');

module.exports = prototype({
  stopEditingResponse: function () {
    delete this.editingResponse;
  },

  showResponse: function (response) {
    this.showingResponse = {
      response: response,
      styles: this.history.stylesForQueryResponse(response) || response.styles
    };
  },

  editing: function () {
    return this.editingResponse && this.editingResponse.response;
  },

  showing: function () {
    return this.showingResponse && this.showingResponse.response;
  },

  selectedResponse: function () {
    return this.editing() || this.showing();
  },

  stopShowingResponse: function () {
    delete this.showingResponse;
  },

  editResponse: function (response) {
    this.editingResponse = {
      response: response,
      styles:
        this.history.stylesForQueryResponse(response)
          || JSON.parse(JSON.stringify(response.styles))
    };
  },

  render: function () {
    var self = this;

    function styleTabContents(response, id, options) {
      return h('.ui.tab.bottom.attached.segment.style-' + id, {class: {editing: options.editing}},
        options.editing
        ? responseHtmlEditor({
            class: 'response-text-editor',
            binding: [response.styles, id, stripNbsp]
          })
        : h.rawHtml('.response-text', response? response.styles[id]: ''),
        h('div', 'response: ', response? response.styles[id]: '')
      );
    }

    function styleTabs(tabs) {
      function styleEdited(id) {
        return response && response.response.styles[id] != response.styles[id];
      }

      var response = self.editingResponse || self.showingResponse;
      var style = self.documentStyle.style;

      return [
        h('.response-tabs',
          semanticUi.tabs(
            '.ui.tabular.menu.top.attached',
            {
              binding: [self.documentStyle, 'style'],
              tabs: tabs.map(function (tab) {
                return {
                  key: tab.id,
                  tab: h('a.item.style-' + tab.id, {class: {edited: styleEdited(tab.id)}}, tab.name),
                  content: function () {
                    return styleTabContents(
                      response,
                      tab.id,
                      {
                        editing: self.editingResponse,
                      }
                    );
                  }
                }
              })
            }
          ),
          self.editingResponse
            ? h('.actions',
                h('button.ui.button',
                  {
                    onclick: function (ev) {
                      var promise = self.selectResponse(response.response, response.styles);
                      self.stopEditingResponse();
                      return promise;
                    }
                  },
                  'ok'
                ),
                ' ',
                h('button.ui.button',
                  {
                    onclick: function (ev) {
                      self.stopEditingResponse();
                    }
                  },
                  'cancel'
                ),
                styleEdited(style)
                  ? [
                      ' ',
                      h('button.ui.button', {
                        onclick: function (ev) {
                          response.styles[style] = response.response.styles[style];
                        }
                      }, 'revert')
                    ]
                  : undefined
              )
            : undefined
        )
      ];
    }

    return h('.response-editor',
      styleTabs([
        {name: 'Normal', id: 'style1', active: true},
        {name: 'Abbreviated', id: 'style2'}
      ])
    )
  }
});
