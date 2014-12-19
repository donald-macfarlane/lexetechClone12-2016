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
        name = 'new_block'
        path = 'blocks/new'
        handler = require './routes/authoring/blocks/new'
      }
      Route {
        name = 'block'
        path = 'blocks/:id'
        handler = require './routes/authoring/blocks/queries'
      }
      Route {
        name = 'edit_block'
        path = 'blocks/:id/edit'
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
      http = require 'jquery'
    }
    router = React.createElement(Handler, globalProps)
    React.render(router, element)
