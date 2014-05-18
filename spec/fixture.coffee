through = require "./index"
sinon = require "sinon"
{Promise} = require "es6-promise"

Deferred = () ->
  @promise = new Promise (resolve, reject) =>
    @resolve_ = resolve
    @reject_ = reject

  return @

Deferred::resolve = -> @resolve_.apply @promise, arguments

Deferred::reject = -> @reject_.apply @promise, arguments

Deferred::then = -> @promise.then.apply @promise, arguments

Deferred::catch = -> @promise.catch.apply @promise, arguments

spy = (stream) ->
  if spy.free.length is 0
    agent1 = sinon.spy()
    agent2 = sinon.spy()
  else if spy.free.length is 1
    agent1 = spy.free.pop()
    agent1.reset()
    agent2 = sinon.spy()
  else
    agent1 = spy.free.pop()
    agent2 = spy.free.pop()
    agent1.reset()
    agent2.reset()

  spy.used.push agent1
  spy.used.push agent2
  
  stream.spy = agent1
  stream.spy2 = agent2

  transform = stream._transform
  each = stream._each

  stream._transform = (c) ->
    agent1 c
    transform.apply @, [].slice.call(arguments)

  stream._each = ->
    agent2 @, [].slice.call(arguments)
    each.apply @, [].slice.call(arguments)
  return

spy.free = []
spy.used = []

extendCtx = (fn) ->
  @thr = fn.factory @optA
  @thrX = fn.factory @optB

  @noop = @thr()

  @stA = @thr()
  @stB = @thr @optA
  @stC = @thr (c) -> @next @chunk

  spy @stA
  spy @stB
  spy @stC

  @streamsArray = [@stA, @stB, @stC, @stX, @stY]
  @dataArray = [@data1, @data2]

  @cache = []
  @defer = new Deferred()

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

module.exports =
  bufferMode: bufferMode
  objectMode: objectMode
  Deferred: Deferred
  spy: spy
