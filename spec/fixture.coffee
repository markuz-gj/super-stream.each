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
    return transform.apply @, [].slice.call(arguments)

  stream._transform.original = transform

  stream._each = ->
    agent2 @, [].slice.call(arguments)
    return each.apply @, [].slice.call(arguments)

  stream._each.original = each
  return

spy.free = []
spy.used = []

extendCtx = (fn) ->
  @thr = fn.factory @optA
  @thrX = fn.factory @optB

  @noop = @thr()

  deferF = new Deferred()

  @stA = @thr()
  @stB = @thr @optA

  @stC = @thr (c) -> 
    @push c
    @counter ?= 0
    @counter += 1

  @stD = @thr @optA, (c) -> 
    @push c
    @counter ?= 0
    @counter += 1

  @stE = @thr (c,e,n) -> 
    @counter ?= 0
    @counter += 1
    n null, c
    return null 
  @stF = @thr @optA, (c,e,n) ->  
    @counter ?= 0
    @counter += 1
    n null, c
    return null 

  spy @stA
  spy @stB
  spy @stC
  spy @stD
  spy @stE
  spy @stF

  @stError = @thr (c,e,n) ->  return new Error 'stError'
  spy @stError

  @stPromise = @thr (c) ->
    defer = new Deferred()
    setImmediate -> defer.resolve c

    return defer.promise
  spy @stPromise

  @stPromiseError = @thr (c) ->
    defer = new Deferred()
    @counter ?= 0
    @counter += 1
    setImmediate => 
      if @counter > 1
        return defer.reject new Error 'stPromiseError'
      defer.resolve c

    return defer.promise
  spy @stPromiseError

  @streamsArray = [@stA, @stB, @stC, @stD, @stE, @stF, @stX, @stY, @stZ]

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
      @stY = fn.buf (c,e,n) -> n(null, c)

      # @optB should be ignored. expect this to throw if it were not.
      @stZ = fn.buf @optB, (c,e,n) -> n(null, c)

      spy @stX
      spy @stY
      spy @stZ

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
      @optB = {objectMode: no}
      @data1 = "data1"
      @data2 = "data2"

      @stX = fn.obj()
      @stY = fn.obj (c,e,n) -> n(null, c)
      
      # @optB should be ignored. expect this to NOT throw if it were not.
      @stZ = fn.obj @optB, (c,e,n) -> n(null, c)

      spy @stX
      spy @stY
      spy @stZ

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
