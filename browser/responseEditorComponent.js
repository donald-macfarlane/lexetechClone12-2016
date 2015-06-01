var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var mediumEditor = require('plastiq-medium-editor');

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
      return h('.ui.tab.bottom.attached.segment', {class: 'style-' + id},
        options.editing
        ? [
            mediumEditor({
              class: 'response-text-editor',
              binding: [response.styles, id],

              mediumOptions: {
                buttons: ['bold', 'italic', 'header1', 'header2', 'unorderedlist', 'orderedlist']
              }
            }),

            h('button', {
              onclick: function (ev) {
                var promise = self.selectResponse(response.response, response.styles);
                self.stopEditingResponse();
                return promise;
              }
            }, 'ok'),
            ' ',
            h('button', {
              onclick: function (ev) {
                self.stopEditingResponse();
              }
            }, 'cancel'),
            options.edited
              ? [
                  ' ',
                  h('button', {
                    onclick: function (ev) {
                      response.styles[id] = response.response.styles[id];
                    }
                  }, 'revert')
                ]
              : undefined
          ]
        : h.rawHtml('.response-text', response? response.styles[id]: '')
      );
    }

    function styleTabs(tabs) {
      function styleEdited(id) {
        return response && response.response.styles[id] != response.styles[id];
      }

      var response = self.editingResponse || self.showingResponse;

      return [
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
                      edited: styleEdited(tab.id)
                    }
                  );
                }
              }
            })
          }
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