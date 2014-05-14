###*
 * @module super-stream/etc
 * @author Marcos GJ 
 * @license MIT
 * @desc some helper functions
 ###

path = require "path"
{readFile, writeFile} = require "fs"
{exec} = require "child_process"
{Promise} = require "es6-promise"

gulp = require "gulp"
{colors, log, replaceExtension} = require "gulp-util"
{bold, red, magenta} = colors

coffee = require "gulp-coffee"
jsdoc = require "gulp-jsdoc"

express = require "express"
livereload = require "gulp-livereload"
tinylr = require "tiny-lr"
conn = require "connect"
conn.livereload = require 'connect-livereload'
conn.markdown = require "marked-middleware"

wait = require ('lodash.throttle')

each = require './index'
thr = each.obj



###*
 * @constructor
 * @return {Defered} - A deferred promise
 * @description - A simple wraper around es6-promise
###
Deferred = () ->
  @promise = new Promise (resolve, reject) =>
    ###*
     * @private
     * @type {Function}
    ###
    @resolve_ = resolve

    ###*
     * @private
     * @type {Function}
    ###
    @reject_ = reject

  return @

###*
 * An alias for `resolve` calback function
 * @memberOf Deffered 
###
Deferred::resolve = -> @resolve_.apply @promise, arguments
  
###*
 * An alias for `reject` calback function
 * @memberOf Deffered 
###
Deferred::reject = -> @reject_.apply @promise, arguments
  
###*
 * An alias for `then` method
 * @memberOf Deffered 
###
Deferred::then = -> @promise.then.apply @promise, arguments
  
###*
 * An alias for `catch` method
 * @memberOf Deffered 
###
Deferred::catch = -> @promise.catch.apply @promise, arguments

###*
  * @param {Object} evt - event object from gulp.watch
  * @param {String} code - code value to be passed to process.exit
  ###
exit = (evt, code = 0) ->
  if evt.type is 'changed'
    log bold red "::: Existing gulp task now :::"
    process.exit code

###*
  * @param {String} cmd - a shell command to be passed to child_process.exec
  * @returns {Promise} - A promise which resolve whenever child_process closes or reject on error event only.
  ###
shell = (cmd) ->
  return new Promise (resolve, reject) ->
    cache =
      stdout: []
      stderr: []

    stream = exec cmd
    stream.on "error", reject

    stream.stdout.pipe thr (f,e,n) -> cache.stdout.push f; n()
    stream.stderr.pipe thr (f,e,n) -> cache.stderr.push f; n()

    stream.on "close", (code) ->
      str = cache.stdout.join ''
      str = "#{str}\n#{cache.stderr.join ''}"
      resolve(str)

###*
  * @param {String} spec - filename of the test file to be run
  * @returns {Function} - A gulp task
  ###
mocha =  (spec) ->
  ->
    cmd = "./node_modules/mocha/bin/mocha  --compilers coffee:coffee-script/register #{spec} -R spec -t 1000 "
    shell cmd
      .then (str) ->
        console.log str
      .catch (err) ->
        throw new Error err

###*
  * @param {String} spec - filename of the test to be run
  * @returns {Function} - A gulp task
  ###
istanbul = (spec) ->
  spec = replaceExtension spec, ".js"
  ->
    cmd = "./node_modules/istanbul/lib/cli.js cover --report html ./node_modules/mocha/bin/_mocha -- #{spec} -R dot -t 1000"
    
    shell cmd
      .then (str) ->
        buf = []
        buf.push "Istanbul coverage summary:"
        buf.push "=================================="
        buf.push str.split('\n')[-11..-8].join('\n')
        buf.push "==================================\n"

        console.log buf.join '\n'

      .catch (err) ->
        throw new Error err
###*
  * @param {String} glob - glob pattern to watch. NOTE: doesn't support an array.
  * @returns {Function} - A gulp task
  * @desc 
  * It creates a express/livereload servers and server the `./coverage/index.html`, `./jsdoc/index.html` and `./*.md` diles
  ###
server =  (glob) ->

  glob ?= do ->
    # little hack to trigger a reload when the task is first fired up
    # not perfect, but get the job done
    shell 'sleep 1 && touch index.coffee'
    return './{spec,index}.coffee'

  app = express()

  app.use conn.errorHandler {dumpExceptions: true, showStack: true }
  app.use conn.livereload()
  app.use conn.markdown {directory: __dirname}

  app.use '/coverage', express.static path.resolve './coverage'
  app.use '/jsdoc', express.static path.resolve './jsdoc'

  app.listen 3001, ->
    log bold "express server running on port: #{magenta 3001}"

  serverLR = tinylr {
    liveCSS: off
    liveJs: off
    LiveImg: off
  }

  lrUp = new Promise (resolve, reject) ->
    serverLR.listen 35729, (err) ->
     return reject err if err
     resolve serverLR

  run = (evt) ->
    if evt.type isnt 'added'
      lrUp.then ->
        log 'reloading', magenta "./#{path.relative(process.cwd(), evt.path)}"
        gulp.src evt.path
          .pipe livereload serverLR

  run = wait run, 500, {trailing: yes, leading: no}
  ->
    gulp.watch glob, run

###*
  * @private
  * @returns {Transform} - A `Transform` Stream which extract all jsdoc @desc tags, concat them and write a `README.md`
  ###
writeReadme = ->

  fixLine = (line) ->
    line.replace /^[ ]*\* (@description|@example|@readme|@desc)/, ''
      .replace /^[ ]*\*/, ''
      .replace /^[ ]/, ''

  return thr (f, e, n) ->
    return n null, f if f.path.match /md$/
    
    cache = {}
    cache.str = []
    cache.bool = no
    cache.buf = []

    file = f.contents.toString()
    file.split('\n').map (line) ->

      if cache.bool and line.match /\* @/
        cache.bool = no

      if line.match /\*\//
        cache.bool = no
        if cache.buf.length
          cache.str.push cache.buf.join '\n'
        cache.buf = []

      if line.match(/\* (@desc|@readme|@example)/)
        cache.bool = yes

      if cache.bool
        cache.buf.push fixLine line

    writeFile './README.md', cache.str.join('\n'), (err) ->
      n err if err
      n null, f

###*
  * @private
  * @returns {Transform} - A `Transform` Stream which un-escape ##\# 
  * @desc Coffeescript triple # comment style conflics with markdown triple #. 
  * So the markdown triple # are "escaped" and this stream un-escapes it. :) cool hack hum?.
  ###
fixMarkdown = ->
  thr (f,e,n) ->
    f.contents = new Buffer f.contents.toString().replace(/\\#/g,'#').replace('\*#', '##')
    n null, f

###*
  * @private
  * @returns {Transform} - A `Transform` Stream which extract all block code language type metatdata. 
  ###
fixJsdoc = ->
  thr (f, e, n) ->
    cache = {}
    cache.str = []
    cache.bool = no
    cache.buf = []

    f.contents = new Buffer f.contents.toString().replace /(```javascript|```)/g, ''
    n null, f

###*
 * @param {String} src - glob pattern to watch. NOTE: doesn't support an array
 * @returns {Function} - A gulp task
 ###
compileDoc = (src) ->
  # # sample template config

  # template = {
  #   path: 'ink-docstrap'
  #   systemName: 'super-stream'
  #   # footer: ':)'
  #   copyright: "2014 (c) MIT"
  #   navType: "vertical"
  #   theme: "spacelab"
  #   linenums: yes
  #   collapseSymbols: no
  #   inverseNav: no
  # }

  config =
    plugins: ['plugins/markdown']
    markdown: 
      parser: 'gfm'
      hardwrap: yes
      readme: './README.md'

  -> 
    gulp.src [replaceExtension(src, '.js')]
      .pipe fixMarkdown()
      .pipe writeReadme()
      .pipe fixJsdoc()
      .pipe jsdoc.parser config
      .pipe jsdoc.generator 'jsdoc'
      # .pipe jsdoc.generator 'jsdoc', template

###*
 * @param {String|Array} globs - glob pattern to watch
 * @returns {Function} - A gulp task
 ###
compileCoffee = (globs) ->
  -> 
    gulp.src globs
      .pipe coffee {bare: yes}
      .pipe gulp.dest('.')

module.exports =
  exit: exit
  shell: shell
  mocha: mocha
  istanbul: istanbul
  server: server
  jsdoc: compileDoc
  coffee: compileCoffee
  Deferred: Deferred

