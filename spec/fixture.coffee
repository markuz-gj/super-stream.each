through = require "./index"
sinon = require "sinon"
{Promise} = require "es6-promise"

spy = (stream, transform) ->
  if spy.free.length is 0
    agent = sinon.spy()
  else
    agent = spy.free.pop()
    agent.reset()

  spy.used.push agent
  fn = stream._transform
  stream.spy = agent

  transform = transform or (c) ->
    agent c
    fn.apply @, arguments

  stream._transform = transform

  return agent

spy.free = []
spy.used = []

extendCtx = (fn) ->
  @thr = fn.factory @optA
  @thrX = fn.factory @optB

  @noop = @thr()

  @stA = @thr()
  @stB = @thr @optA

  spy @stA
  spy @stB

  @streamsArray = [@stA, @stB, @stX, @stY]
  @dataArray = [@data1, @data2]
  
bufferMode = 
  desc: 'streams in buffer mode:'
  before: (fn) ->
    ->
      @optA = {}
      @optB = {objectMode: yes}
      @data1 = new Buffer "data1"
      @data2 = new Buffer "data2"

      @stX = fn.buf()
      spy @stX

      @stY = fn.buf (c,e,n) -> n(null, c)
      spy @stY

      extendCtx.call @, fn
      return @

  after: ->
    for agent in spy.used
      spy.free.push spy.used.pop()

objectMode = 
  desc: 'streams in object mode:'
  before: (fn) ->
    ->
      @optA = {objectMode: yes}
      @optB = {}
      @data1 = "data1"
      @data2 = "data2"

      @stX = fn.obj()
      spy @stX

      @stY = fn.obj (c,e,n) -> n(null, c)
      spy @stY

      extendCtx.call @, fn
      return @
    
  after: ->
    for agent in spy.used
      spy.free.push spy.used.pop()

Deferred = () ->
  @promise = new Promise (resolve, reject) =>
    @resolve_ = resolve
    @reject_ = reject

  return @

Deferred::resolve = -> @resolve_.apply @promise, arguments

Deferred::reject = -> @reject_.apply @promise, arguments

Deferred::then = -> @promise.then.apply @promise, arguments

Deferred::catch = -> @promise.catch.apply @promise, arguments

module.exports =
  bufferMode: bufferMode
  objectMode: objectMode
  Deferred: Deferred
  spy: spy
