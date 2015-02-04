var React = require('react');
var r = React.createElement;
var Medium = require('medium-editor');

module.exports = React.createFactory(React.createClass({
  componentDidMount: function() {
    var self = this;
    var element = this.getDOMNode();

    if (this.props.value) {
      element.innerHTML = this.props.value;
    } else {
      element.innerHTML = '<p><br></p>';
    }

    var editor = new Medium(element);

    element.addEventListener('input', function (ev) {
      if (self.props.onChange) {
        self.props.onChange(ev);
      }
    });
  },

  componentDidUpdate: function () {
  },

  render: function () {
    return r('div', { className: 'editor' });
  }
}));
