var h = require('plastiq').html;
var removeFromArray = require('../../../../removeFromArray');
var _ = require('underscore');

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
      onadd: function () {
        this.search = '';
      }
    },
    function (component) {
      var state = component.state;

      state.search = state.search || '';

      function focus() {
        state.show = true;
      }

      function blur(ev) {
        if (!state.activated) {
          state.show = false;
        } else {
          ev.target.focus();
        }
      }

      function activate() {
        state.activated = true;
      }

      function disactivate() {
        state.activated = false;
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

        return h("a.item", {href: '#', onclick: select},
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
        return matchesSearch(p, state.search);
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
            binding: [state, 'search'],
            onkeydown: searchKeyDown,
            onblur: blur,
            onfocus: focus
          }
        ),
        h("div.select-list",
          h(".ui.menu.vertical", {class: {hidden: !state.show}}, matchingItems.map(renderMatchingItem))
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
