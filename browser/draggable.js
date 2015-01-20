var React = require('react');
var placeholder = document.createElement("li");
placeholder.className = "placeholder";
$ = require('jquery')

module.exports = function (options) {
  options = options || {};

  var listElement = function (element) {
    if (options.listSelector) {
      return $(element).find(options.listSelector)[0];
    } else {
      return element;
    }
  }

  var itemElements = function (element) {
    var selector = options.itemSelector || 'li[draggable=true]';

    return $(element).find(selector);
  }

  return {
    componentDidMount: function () {
      this.componentDidUpdate();
    },
    componentDidUpdate: function () {
      var list = listElement(this.getDOMNode());
      function draggableTarget(element) {
        return $(element).closest('li[draggable=true], .placeholder')[0];
      }

      var self = this;

      self.eventListenerRemovers = [];
      function addEventListener(element, event, listener) {
        self.eventListenerRemovers.push(function () {
          element.removeEventListener(event, listener);
        });

        element.addEventListener(event, listener);
      }

      addEventListener(list, 'dragover', function (e) {
        console.log('dragover');
        if (!$.contains(list, e.target) || !self.dragged) {
          return;
        }
        var target = draggableTarget(e.target);
        if (!target) {
          return;
        }

        e.preventDefault();

        self.dragged.style.display = "none";
        if(target == placeholder) return;
        if(target == self.dragged) return;
        console.log('dragover not placeholder, and not dragged');
        self.over = target;
        // Inside the dragOver method
        var relY = e.clientY + window.scrollY - $(self.over).offset().top;
        var height = self.over.offsetHeight / 2;

        if(relY > height) {
          self.nodePlacement = "after";
          list.insertBefore(placeholder, target.nextElementSibling);
        }
        else if(relY < height) {
          self.nodePlacement = "before"
          list.insertBefore(placeholder, target);
        }
      });

      var items = itemElements(list);

      for (var n = 0; n < items.length; n++) {
        var item = items[n];
        item.dataset.draggableId = n;

        addEventListener(item, 'dragstart', function (e) {
          console.log('dragstart');
          try {
            var currentTarget = draggableTarget(e.currentTarget);
            self.dragged = currentTarget;
            e.dataTransfer.effectAllowed = 'move';
            $(placeholder).height($(self.dragged).height());
            
            // Firefox requires dataTransfer data to be set
            e.dataTransfer.setData("text/html", currentTarget);
            console.log('dragstart kind of done');
          } catch (e) {
            console.log('dragstart error', e);
          } finally {
            console.log('dragstart finally');
          }
        });
        addEventListener(item, 'drag', function (e) {
          console.log('drag');
          if (!placeholder.parentNode) {
            list.insertBefore(placeholder, self.dragged.nextElementSibling);
          }
        });
        addEventListener(item, 'dragend', function (e) {
          console.log('dragend');
          self.dragged.style.display = "block";
          self.dragged.parentNode.removeChild(placeholder);

          // Update data
          var from = Number(self.dragged.dataset.draggableId);
          if (self.over) {
            var to = Number(self.over.dataset.draggableId);
            if(from < to) to--;
            console.log('item dragged', from, to);
            if(self.nodePlacement == "after") to++;
            self.itemDragged(from, to);
            delete self.dragged;
          }
        });
      }
    },
    componentWillUpdate: function () {
      for(var n = 0; n < this.eventListenerRemovers.length; n++) {
        this.eventListenerRemovers[n]();
      }
    }
  };
}
