React = require 'react'
ReactRouter = require 'react-router'
documentApi = require './documentApi'

module.exports (element, queryApi, pageData, options) =
  Route = ReactRouter.Route
  DefaultRoute = ReactRouter.DefaultRoute
  NotFoundRoute = ReactRouter.NotFoundRoute
  RouteHandler = ReactRouter.RouteHandler
  r = React.createElement

  routes = r (Route) { handler = require './routes/layout' } (
    r (NotFoundRoute) {
      handler = require './routes/notFound'
    }
    r (Route) {
      path = '/authoring'
      handler = require './routes/authoring/layout'
    } (
      r (DefaultRoute) {
        name = 'authoring'
        handler = require './routes/authoring/index'
      }
      r (NotFoundRoute) {
        handler = require './routes/notFound'
      }
      r (Route) {
        name = 'create_block'
        path = 'blocks/create'
        handler = require './routes/authoring/index'
      }
      r (Route) {
        name = 'block'
        path = 'blocks/:blockId'
        handler = require './routes/authoring/index'
      }
      r (Route) {
        name = 'create_query'
        path = 'blocks/:blockId/queries/create'
        handler = require './routes/authoring/index'
      }
      r (Route) {
        name = 'query'
        path = 'blocks/:blockId/queries/:queryId'
        handler = require './routes/authoring/index'
      }
      r (Route) {
        name = 'edit_block'
        path = 'blocks/:blockId/edit'
        handler = require './routes/authoring/index'
      }
    )
    r (Route) {
      name = 'login'
      path = '/login'
      handler = require './routes/login'
    }
    r (Route) {
      name = 'signup'
      path = '/signup'
      handler = require './routes/signup'
    }
  )

  locationApi =
    if (options @and options.historyApi == false)
      ReactRouter.HashLocation
    else
      ReactRouter.HistoryLocation

  ReactRouter.run(routes, locationApi) @(Handler)
    globalProps = {
      queryApi = queryApi
      user = pageData.user
      http = require './http'
      documentApi = documentApi()
    }
    router = r(Handler, globalProps)
    React.render(router, element)
