module.exports (element, queryApi, pageData, options) =

  React = require 'react'
  ReactRouter = require 'react-router'
  Route = React.createFactory(ReactRouter.Route)
  DefaultRoute = React.createFactory(ReactRouter.DefaultRoute)
  NotFoundRoute = React.createFactory(ReactRouter.NotFoundRoute)
  RouteHandler = React.createFactory(ReactRouter.RouteHandler)
  r = React.createElement

  routes = Route { handler = require './routes/layout' } (
    DefaultRoute {
      name = 'reports'
      handler = require './routes/home'
    }
    NotFoundRoute {
      handler = require './routes/notFound'
    }
    Route {
      path = '/authoring'
      handler = require './routes/authoring/layout'
    } (
      DefaultRoute {
        name = 'authoring'
        handler = require './routes/authoring/index'
      }
      NotFoundRoute {
        handler = require './routes/notFound'
      }
      Route {
        name = 'create_block'
        path = 'blocks/create'
        handler = require './routes/authoring/blocks/block'
      }
      Route {
        name = 'block'
        path = 'blocks/:blockId'
        handler = require './routes/authoring/blocks/block'
      }
      Route {
        name = 'create_query'
        path = 'blocks/:blockId/queries/create'
        handler = require './routes/authoring/blocks/block'
      }
      Route {
        name = 'query'
        path = 'blocks/:blockId/queries/:queryId'
        handler = require './routes/authoring/blocks/block'
      }
      Route {
        name = 'edit_block'
        path = 'blocks/:blockId/edit'
        handler = require './routes/authoring/blocks/edit'
      }
    )
    Route {
      name = 'login'
      path = '/login'
      handler = require './routes/login'
    }
    Route {
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
    }
    router = React.createElement(Handler, globalProps)
    React.render(router, element)
