embed = require '../../lib/assets/embed_datauri'
path = require 'path'

it 'embeds assets via data-uri from a string of css', ->
  embedded = embed """
    .foo: {
      background: url('images/artsy-logotype-white.svg')
    }
  """, path.resolve(__dirname, '../../public/')
  embedded.should.containEql('data:image/svg+xml;base64,PD94bWwgdmVyc2l')
