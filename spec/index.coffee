{Transform} = require "readable-stream" 

chai = require "chai"
sinon = require "sinon"
chai.use require "sinon-chai"

# once = require "lodash.once"

expect = chai.expect
chai.config.showDiff = no

each = require ".."
{bufferMode, objectMode, Deferred, spy} = require "./fixture"

describe "exported value:", ->
  it 'must be a function', ->
    expect(each).to.be.an.instanceof Function

  it "must have obj property", ->
    expect(each).to.have.property "obj"
    expect(each.obj).to.be.an.instanceof Function

  it "must have buf property", ->
    expect(each).to.have.property "buf"
    expect(each.buf).to.be.an.instanceof Function

  it "must have factory property", ->
    expect(each).to.have.property "factory"
    expect(each.factory).to.be.an.instanceof Function



for mode in [bufferMode, objectMode]
  do (mode) ->
    describe mode.desc, ->
      beforeEach mode.before each
      afterEach mode.after

      it "must return an instanceof Transform", ->
        @defer.resolve()
        return @defer.then =>
          @streamsArray.map (stream, i) =>
            expect(stream).to.be.an.instanceof Transform

      it "must return a noop stream if called without arguments", ->
        @defer.resolve()
        return @defer.then =>
          @noop.pipe @thr (c,e,n) => expect(c).to.be.equal @data1
          @noop.write @data1

      it "must pass data through stream unchanged", ->
        @streamsArray.map (stream, i) =>
          stream.write @data1
          @cache.push stream.spy

        @defer.resolve()
        return @defer.then =>
          @cache.map (spy, i) =>
            expect(spy).to.have.been.calledWith @data1
            expect(spy).to.have.been.calledOnce

      it "must be able to re-use the same stream multiple times", ->
        @streamsArray.map (stream, i) =>
          @dataArray.map (data, j) =>
            stream.write data
            @cache.push {spy: stream.spy, data: data}

        @defer.resolve()
        return @defer.then =>
          @cache.map (v, i) =>
            expect(v.spy).to.have.been.calledWith v.data
            expect(v.spy).to.have.callCount @dataArray.length

      it "must pass data down stream multiple times", ->
        lastSpy = @streamsArray[-1..-1][0].spy
        @noop.pipe @streamsArray[0]

        @streamsArray.map (stream, i) =>
          if i is @streamsArray.length - 1
            @dataArray.map (data, j) => @noop.write data
            return 
          stream.pipe @streamsArray[i + 1]
        
        @defer.resolve()
        return @defer.then =>
          expect(lastSpy).to.have.callCount @dataArray.length
          @dataArray.map (data, i) =>
            expect(lastSpy).to.have.been.calledWith data


      describe "stream contex:", ->

        it "must have only `chunk`, `encoding`, `next` on the stream inner ctx", ->
          @streamsArray.map (stream, i) =>
            @dataArray.map (data, j) =>
              stream.write data
              @cache.push {stream: stream, data: data}
          
          @defer.resolve()
          return @defer.then =>
            @cache.map (v, i) =>
              expect(v.stream).to.not.have.property "chunk"
              expect(v.stream).to.not.have.property "encoding"
              expect(v.stream).to.not.have.property "next"

              v.stream.spy2.args.map (x) ->
                ctx = x[0]
                expect(ctx).to.have.property "chunk"
                expect(ctx).to.have.property "encoding"
                expect(ctx).to.have.property "next"

        it "must have `this.chunk` being equal to the data passed into transform", ->
          @streamsArray.map (stream, i) =>
            @dataArray.map (data, j) =>
              stream.write data
              @cache.push {stream: stream, data: data}
          
          @defer.resolve()
          return @defer.then =>
            @cache.map (v, i) =>
              v.stream.spy2.args.map (x, j) ->
                ctx = x[0]
                args = x[1]
                expect(ctx.chunk).to.be.equal args[0]

        it "must have `this.encoding` being the rigth encoding", ->
          @streamsArray.map (stream, i) =>
            @dataArray.map (data, j) =>
              stream.write data
              @cache.push {stream: stream, data: data}
          
          @defer.resolve()
          return @defer.then =>
            @cache.map (v, i) =>
              v.stream.spy2.args.map (x, j) ->
                ctx = x[0]
                args = x[1]
                expect(ctx.encoding).to.be.equal args[1]

        it "must have a `this._each` property on stream ctx and not as own property", ->
          @streamsArray.map (stream, i) =>
            @dataArray.map (data, j) =>
              stream.write data
              @cache.push {stream: stream, data: data}
          
          @defer.resolve()
          return @defer.then =>
            @cache.map (v, i) =>
              expect(v.stream).have.property "_each"

              v.stream.spy2.args.map (x) ->
                expect(x[0]).to.not.have.ownProperty "_each"
                expect(x[0]).to.have.property "_each"

        it "must not remove any property added to the inner ctx", ->
          @streamsArray.map (stream, i) =>
            @dataArray.map (data, j) =>
              stream.write data
              @cache.push {stream: stream, data: data}
          
          @defer.resolve()
          return @defer.then =>
            @cache.map (v, i) =>
              expect(v.stream).have.property "_each"

              v.stream.spy2.args.map (x) ->
                expect(x[0]).to.not.have.ownProperty "_each"
                expect(x[0]).to.have.property "_each"


