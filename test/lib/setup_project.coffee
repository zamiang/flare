setup = require '../../lib/setup.coffee'
Backbone = require 'backbone'
express = require 'express'
sd = require '../../lib/shared_data'
config = require '../../config'
sinon = require 'sinon'

describe 'Project setup', ->

  before ->
    @app = express()
    setup @app

  it 'sets the JS_EXT and CSS_EXT for normal .js an .css for dev', ->
    sd.JS_EXT.should.equal '.js'
    sd.CSS_EXT.should.equal '.css'

  context 'for production', ->

    beforeEach ->
      @app = express()
      @app.set 'env', 'production'
      setup @app

    it 'sets the JS_EXT and CSS_EXT for production', ->
      sd.JS_EXT.should.equal '.min.js.gz'
      sd.CSS_EXT.should.equal '.min.css.gz'
