var h = require('plastiq').html;
var removeFromArray = require('../../../../removeFromArray');
var _ = require('underscore');

function elementHasParent(element, parent) {
  var e = element;

  while (e.parentNode) {
    if (e.parentNode === parent) {
      return true;
    }

    e = e.parentNode;
  }
}

module.exports = function(options) {
  var items = options.items;
  var selectedItems = options.selectedItems;
  var renderItemText = options.renderItemText;
  var placeholder = options.placeholder;
  var itemAdded = options.itemAdded;
  var itemRemoved = options.itemRemoved;

  return h.component(
    {
      key: options && options.key,

      onadd: function (element) {
        var self = this;

        this.search = '';

        this.outsideClick = h.refreshify(function (ev) {
          if (!elementHasParent(ev.target, element)) {
            self.blur();
          }
        });

        document.addEventListener('click', this.outsideClick, true)
      },

      onremove: function () {
        document.removeEventListener('click', this.outsideClick);
      },

      blur: function (ev) {
        if (!this.activated) {
          this.show = false;
          this.search = '';
        } else {
          ev.target.focus();
        }
      }
    },
    function (component) {
      var self = this;
      this.search = this.search || '';

      function focus() {
        self.show = true;
      }

      function activate() {
        self.activated = true;
      }

      function disactivate() {
        self.activated = false;
      }

      function searchKeyDown(ev) {
        if (ev.keyCode === 13) {
          selectItem(matchingItems[0]);
        }
      }

      function selectItem(p) {
        if (selected[p.id]) {
          var item = selectedItems[p.id];
          removeFromArray(p.id, selectedItems);
          if (itemRemoved) {
            return itemRemoved(p);
          }
        } else {
          selectedItems.push(p.id);
          if (itemAdded) {
            return itemAdded(p);
          }
        }
      }

      function matchesSearch(p, search) {
        if (search === "") {
          return true;
        } else {
          var terms = _.compact(search.toLowerCase().split(/ +/));
          return _.all(terms, function(t) {
            return p.name && p.name.toLowerCase().indexOf(t) >= 0;
          });
        }
      }

      function renderMatchingItem(p) {
        function select() {
          return selectItem(p);
        }

        var text = renderItemText
          ? renderItemText(p)
          : p.name;

        return h("a.item", {onclick: select},
          text,
          selected[p.id]
            ? h.rawHtml("span.selected", "&#x2713;")
            : undefined
        );
      }

      var selected = index(selectedItems);
      var matchingItems = Object.keys(items).map(function (k) {
        return items[k];
      }).filter(function (p) {
        return matchesSearch(p, self.search);
      });

      return h("div.item-select",
        {
          onmousedown: activate,
          onmouseup: disactivate
        },
        h("input",
          {
            type: "text",
            placeholder: placeholder,
            binding: [self, 'search'],
            onkeydown: searchKeyDown,
            onfocus: focus
          }
        ),
        h("div.select-list",
          h(".ui.menu.vertical", {class: {hidden: !self.show}}, matchingItems.map(renderMatchingItem))
        )
      );
    }
  );
};

function index(array) {
  var obj = {};
  for (var n = 0; n < array.length; ++n) {
    obj[array[n]] = true;
  }
  return obj;
}
