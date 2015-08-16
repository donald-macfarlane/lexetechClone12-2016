var self = this;
var React = require("react");
var r = React.createElement;
var ReactRouter = require("react-router");
var Navigation = ReactRouter.Navigation;
var _ = require("underscore");
var sortableReact = require("../sortable");
var plastiq = require('plastiq');
var queryComponent = require('./queryComponent');
var clone = require('./clone');
var loadPredicants = require('../loadPredicants');

function dropdownButton() {
  var args = Array.prototype.slice.call(arguments);
  args.unshift('.drop-down-button');
  return h.apply(undefined, args);
}

module.exports = React.createClass({
  mixins: [ ReactRouter.State, Navigation ],

  getInitialState: function() {
    return {
      query: module.exports.create(),
      predicants: [],
      lastResponseId: 0
    };
  },

  componentDidMount: function() {
    var self = this;

    function loadBlocks() {
      return self.props.http.get("/api/blocks").then(function(blockList) {
        return _.indexBy(blockList, "id");
      });
    }

    var component = queryComponent({
      query: clone(this.props.query),
      originalQuery: this.props.query,
      props: this.props
    });

    plastiq.append(this.getDOMNode(), component.render.bind(component));

    loadBlocks().then(function (blocks) {
      component.blocks = blocks;
      component.refresh();
    });

    loadPredicants().then(function (predicants) {
      component.predicants = predicants;
      component.refresh();
    });
  },

  componentWillReceiveProps: function(newprops) {
    var self = this;
    var clipboardPaste = false;

    newprops.pasteQueryFromClipboard(function(clipboardQuery) {
      clipboardPaste = true;
      _.extend(self.state.query, _.omit(clipboardQuery, "level", "id"));
      return self.setState({
        query: self.state.query,
        dirty: true
      });
    });

    if (!self.state.dirty && !clipboardPaste) {
      self.setState({
        query: clone(newprops.query),
        selectedResponse: undefined
      });
    }
  },

  render: function () {
    return r('div', {});
  },
});

module.exports.create = function(obj) {
  var self = this;
  return _.extend({
    responses: [],
    predicants: [],
    level: 1
  }, obj);
};
