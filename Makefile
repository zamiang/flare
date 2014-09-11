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

# Run all of the project-level tests, followed by app-level tests
test: assets-fast
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find components/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find components/**/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find apps/*/test -name '*.coffee' -not -path 'test/helpers/*')

# Generate minified assets from the /assets folder and output it to /public.
assets:
	$(foreach file, $(shell find assets -name '*.coffee' | cut -d '.' -f 1), \
		$(BIN)/browserify $(file).coffee -t jadeify -t caching-coffeeify -u config.coffee > public/$(file).js; \
		$(BIN)/uglifyjs public/$(file).js > public/$(file).min.js; \
		gzip -f public/$(file).min.js; \
		mv public/$(file).min.js.gz public/$(file).min.js.cgz; \
	)
	$(BIN)/stylus assets -o public/assets --inline --include public/
	$(foreach file, $(shell find assets -name '*.styl' | cut -d '.' -f 1), \
		$(BIN)/sqwish public/$(file).css -o public/$(file).min.css; \
		gzip -f public/$(file).min.css; \
		mv public/$(file).min.css.gz public/$(file).min.css.cgz; \
	)


# Generate unminified assets for testing and development.
assets-fast:
	$(foreach file, $(shell find assets -name '*.coffee' | cut -d '.' -f 1), \
		$(BIN)/browserify --fast $(file).coffee -t jadeify -t caching-coffeeify -u config.coffee > public/$(file).js; \
	)
	$(BIN)/stylus assets -o public/assets

# Runs all the necessary build tasks to push to staging or production
# Run with `make deploy env=staging` or `make deploy env=production`.
deploy: assets
	$(BIN)/bucketassets -d public/assets -b flare-$(env)
	$(BIN)/bucketassets -d public/images -b flare-$(env)
	heroku config:add \
	ASSET_PATH=//$(CDN_DOMAIN_$(env)).cloudfront.net/assets/$(shell git rev-parse --short HEAD)/ \
	--app=flare-$(env)
	git push git@heroku.com:flare-$(env).git master

.PHONY: test
