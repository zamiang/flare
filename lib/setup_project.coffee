# 
# Sets up intial project settings, middleware, mounted apps, and global configuration
# such as overriding Backbone.sync and populating ./shared_data
# 

express = require 'express'
path = require 'path'
Backbone = require 'backbone'
sd = require './shared_data'
asssetMiddleware = require './assets/middleware'
backboneServerSync = require './backbone_server_sync'
gravityXapp = require './gravity_xapp'
localsMiddleware = require './locals_middleware'
redirectToGravity = require './redirect_to_gravity'
{ pageNotFound, internalError } = require '../components/error_handler'
{ PORT, GRAVITY_URL, SESSION_SECRET } = config = require '../config'

module.exports = (app) ->

  # Override backbone sync for server-side requests
  Backbone.sync = backboneServerSync

  # General settings
  app.use redirectToGravity.forDesktopBrowser
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.cookieParser(SESSION_SECRET)
  app.use express.cookieSession()
  app.use gravityXapp.middleware unless app.get('env') is 'test'
  app.use localsMiddleware
  sd.JS_EXT = '.js'
  sd.CSS_EXT = '.css'
  
  # Test settings
  if app.get('env') is 'test'
    sd.GRAVITY_XAPP_TOKEN = 'xapp_foobar'
    fakeGravity = require('../test/helpers/servers').gravity
    app.use '/__gravity', fakeGravity

  # Development settings
  if app.get('env') is 'development'
    app.use asssetMiddleware
    app.get '/local/*', (req, res, next) ->
      res.redirect GRAVITY_URL + req.url

  # Production settings
  if app.get('env') is 'production' or app.get('env') is 'staging'
    sd.JS_EXT = '.min.js.gz'
    sd.CSS_EXT = '.min.css.gz'
  
  # Inject configuration into the shared data
  sd[key] = config[key] ? val for key, val of sd
  
  # Mount apps
  app.use require '../apps/page'
  app.use require '../apps/profile'
  app.use require '../apps/password'
  app.use require '../apps/home'
  app.use require '../apps/artwork'
  app.use require '../apps/feature'
  app.use require '../apps/artist'
  app.use require '../apps/post'
  app.use require '../apps/fair'
  app.use require '../apps/search'
  app.use require '../apps/show'
  
  # More general middleware
  app.use express.static path.resolve __dirname, '../public'
  app.use redirectToGravity.forUnsupportedRoute
  app.use pageNotFound
  app.use internalError