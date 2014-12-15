module.exports (element, queryApi, pageData) =

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

  ReactRouter.run(routes, ReactRouter.HistoryLocation) @(Handler)
    router = React.createElement(Handler, {queryApi = queryApi, user = pageData.user})
    React.render(router, element)
