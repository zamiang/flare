#
# Make -- the OG build tool.
# Add any build tasks here and abstract complex build scripts into `lib` that can
# be run in a Makefile task like `coffee lib/build_script`.
#
# Remember to set your text editor to use 4 size non-soft tabs.
#

BIN = node_modules/.bin

# CloudFront distributions for flare-production and flare-staging buckets
CDN_DOMAIN_production = d2j4e4qugepns1
CDN_DOMAIN_staging = d346buv1lzfvg9

# Start the server
s:
	$(BIN)/coffee index.coffee

# Run all of the tests
test: assets
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find apps/*/test -name '*.coffee' -not -path 'test/helpers/*')

public/assets:
	mkdir -p $@

# Quickly compile assets to public/assets for development
assets: public/assets
	$(BIN)/stylus assets/all.styl -o public/assets
	$(BIN)/browserify assets/all.coffee -t caching-coffeeify -t jadeify > public/assets/all.js

# Compiles assets for production (minifying, embeddeding, gzipping)
assets-production: assets
	$(BIN)/sqwish public/assets/all.css -o public/assets/all.min.css
	$(BIN)/coffee lib/assets/embed_datauri.coffee public/assets/all.min.css
	$(BIN)/uglifyjs public/assets/all.js > public/assets/all.min.js
	gzip -f public/assets/all.min.js public/assets/all.min.css
	rm public/assets/*.js public/assets/*.css

# Uploads assets to S3
assets-to-cdn: assets-production
	$(BIN)/coffee lib/assets/to_cdn.coffee public/assets

# Runs all the necessary build tasks to push to staging or production
deploy: assets-production
	APPLICATION_NAME=flare-$(env) make assets-to-cdn
	heroku config:add ASSET_PATH=//$(CDN_DOMAIN_$(env)).cloudfront.net/assets/$(shell git rev-parse --short HEAD)/ --app=flare-$(env)
	git push -f git@heroku.com:flare-$(env).git master

deploy-staging:
	make deploy env=staging

deploy-production:
	make deploy env=production

.PHONY: test
