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

all: $(DEST) $(DEST)/css/app.css $(DEST)/js/app.js verbatim

server:
	@$(BIN)light-server -s $(DEST) -p 3838 \
		-w "src/js/*.js,src/verbatim/** # $(REPORT)" \
		-w "src/scss/**/*.scss # $(REPORT) # reloadcss"

icons:
	## Generate icons
	# optimize svg files
	@$(BIN)svgo $(SRC)/images/icons --enable=removeTitle --enable=removeViewBox \
		--enable=removeDimensions
	# convert the icons
	@$(BIN)grunticon $(SRC)/images/icons $(DEST)/css --config=grunticon-options.json

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
	# run autoprefixer
	# @$(BIN)postcss --use autoprefixer $(@D)/$(@F) -d $(@D)

$(JS):: $(JS_SRC)
	## Build JS files
	# compile ES6 files
	$(BIN)rollup -c  -- $(SRC)/js/$(*F).js > $@

verbatim:: $(VERBATIM_SRC)
	## Copy static files
	# copy all static files verbatim to the dest folder
	@cp $? $(DEST)/
