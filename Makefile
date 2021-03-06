SHELL := /bin/bash
BIN = ./node_modules/.bin/
DEST = static
SRC = src
REPORT = make 2>&1 | $(BIN)make2tap | $(BIN)tap-summary

CSS_SRC = $(shell find $(SRC)/scss -type f)
CSS = $(DEST)/%.css

JS_SRC = $(shell find $(SRC)/js -type f)
JS = $(DEST)/%.js

VERBATIM_SRC = $(shell find $(SRC)/verbatim/*)

DEST_HTML = $(shell find public -name '*.html')

all: $(DEST) $(DEST)/css/app.css $(DEST)/js/app.js verbatim

build: all
	## Optimize files for production
	@make public
	@$(BIN)uncss --htmlroot public public/**/**/*.html public/**/*.html \
		| $(BIN)postcss --use autoprefixer \
		> $(DEST)/css/app.css
	@make public $(DEST_HTML)

server:
	@$(BIN)light-server --quiet \
		-w "src/js/*.js,src/verbatim/** # $(REPORT) # no-reload" \
		-w "src/scss/**/*.scss # $(REPORT) # no-reload"

svg:
	## Prepare svg files
	@$(BIN)svgo $(SRC)/verbatim/icons --enable=removeTitle --enable=removeViewBox \
		--enable=removeDimensions

clean:
	## Clean files
	# Remove static dir
	@rm -rf static
	# Remove public dir
	@rm -rf public

$(DEST):
	## Create public files and dirs
	# create the public dir, if does not exist
	@mkdir -p $@
	# create specific assets dirs
	@mkdir -p $@/{js,css}/

$(CSS):: $(CSS_SRC)
	## Build CSS files
	# compile sass files
	@$(BIN)node-sass --output $(@D) $(SRC)/scss/$(*F).scss $(@D)/$(@F)

$(JS):: $(JS_SRC)
	## Build JS files
	# copy JS source
	cp $(SRC)/js/$(*F).js $@

$(DEST_HTML):
	@$(BIN)inline-source --compress false --root public $@ \
		| $(BIN)html-minifier -o $@.tmp -c .htmlminifyrc
	@mv $@.tmp $@
	@rm -rf $@.tmp

verbatim:: $(VERBATIM_SRC)
	## Copy static files
	# copy all static files verbatim to the dest folder
	@cp -r $? $(DEST)/

public:
	@cp -r $(DEST)/* $@

deploy: clean
	@hugo -D
	@make build
	@$(BIN)netlify deploy

.PHONY: $(DEST_HTML) public
