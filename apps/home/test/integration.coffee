{ startServer, closeServer } = require '../../../test/helpers/servers'
Browser = require 'zombie'

describe 'Home page', ->

  before (done) -> startServer done

  after -> closeServer()

  it 'renders the promo page and lets you submit your phone number', (done) ->
    browser = new Browser
    Browser.visit 'http://localhost:5000', ->
      browser.wait ->
        browser.html().should.containEql 'The art world in your pocket'
        sinon.stub $, 'ajax'
        $('#sms input.phone_number').val('555 102 2432').submit()
        $('#sms button').click()
        $.ajax.args[0][0].url.should.containEql '/send_link'
        $.ajax.args[0][0].data.phone_number.should.equal '555 102 2432'
        done()
