var h = require('plastiq').html;
var semanticUi = require('plastiq-semantic-ui');
var loadPredicants = require('./loadPredicants');
var _ = require('underscore');
var throttle = require('plastiq-throttle');
var http = require('../../../http');

function PredicantsComponent(options) {
  var self = this;

  this.onclose = options.onclose;

  this.predicants = [];
  this.filteredPredicants = [];

  loadPredicants().then(function (predicants) {
    self.predicants = _.values(predicants);
    self.refresh();
  });

  this.search = throttle(function (query) {
    if (query) {
      var lowerCaseQuery = query.toLowerCase();
      this.filteredPredicants = this.predicants.filter(function (predicant) {
        return predicant.name.toLowerCase().indexOf(lowerCaseQuery) >= 0;
      });
    } else {
      this.filteredPredicants = this.predicants;
    }
  });
}

PredicantsComponent.prototype.render = function () {
  var self = this;

  this.refresh = h.refresh;

  this.search(this.query);

  function selectPredicant(predicant) {
    self.selectedPredicant = predicant;
  }

  return semanticUi.modal(
    {
      onHidden: function () {
        self.onclose();
      }
    },
    h('.ui.modal',
      h('i.close.icon'),
      h('.header', 'Predicants'),
      h('.content',
        h('.ui.horizontal.segments',
          h('.ui.segment',
            h('.ui.icon.input',
              h('input', {type: 'text', placeholder: 'search predicants', binding: [this, 'query']}),
              h('i.search.icon')
            ),
            h('.ui.vertical.menu.results',
              this.filteredPredicants.map(function (predicant) {
                return h('a',
                  {
                    href: '#',
                    onclick: function (ev) {
                      selectPredicant(predicant);
                      ev.preventDefault();
                    }
                  },
                  h('h5', predicant.name)
                );
              })
            )
          ),
          h('.ui.segment',
            self.selectedPredicant
              ? h('.predicant',
                  h('h1', 'Predicant'),
                  h('input', {type: 'text', binding: [self.selectedPredicant, 'name']}),
                  h('.ui.button', {
                    onclick: function () {
                      return http.put(self.selectedPredicant.href, self.selectedPredicant).then(function () {
                        delete self.selectedPredicant;
                        self.refresh();
                      });
                    }
                  }, 'Save')
                )
              : undefined
          )
        )
      )
    )
  );
};

module.exports = function (options) {
  return new PredicantsComponent(options);
};
