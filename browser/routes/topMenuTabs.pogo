React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
r = React.createElement

module.exports = React.createClass {
  getInitialState() = {}

  componentDidMount() =
    self.setState {
      currentDocument = self.props.documentApi.currentDocument()!
    }
    
  render() =
    if (self.props.user)
      r 'div' { className = 'tabs' } (
        r 'a' { href = '/' } 'Home'
        if (self.state.currentDocument)
          r 'a' { href = "/reports/#(self.state.currentDocument.id)" } (
            if (self.state.currentDocument.name)
              "Report: #(self.state.currentDocument.name)"
            else
              "Report"
          )

        Link { to = 'authoring', className = 'active' } 'Authoring'
      )
    else
      r 'div' { className = 'tabs' }
}
