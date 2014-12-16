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
      handler = require './routes/home'
    }
    NotFoundRoute {
      handler = require './routes/notFound'
    }
    Route {
      name = 'authoring'
      path = '/authoring'
      handler = require './routes/authoring'
    }
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
    router = React.createElement(Handler, {queryApi = queryApi, user = pageData.user})
    React.render(router, element)
