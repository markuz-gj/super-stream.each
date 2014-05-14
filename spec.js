var Deferred, Transform, bufferMode, chai, each, expect, mode, objectMode, sinon, _fn, _i, _len, _ref, _ref1;

Transform = require("readable-stream").Transform;

chai = require("chai");

sinon = require("sinon");

chai.use(require("sinon-chai"));

expect = chai.expect;

chai.config.showDiff = false;

each = require("./index");

_ref = require("./fixture"), bufferMode = _ref.bufferMode, objectMode = _ref.objectMode, Deferred = _ref.Deferred;

describe("exported value:", function() {
  it('must be a function', function() {
    return expect(each).to.be.an["instanceof"](Function);
  });
  it("must have obj property", function() {
    expect(each).to.have.property("obj");
    return expect(each.obj).to.be.an["instanceof"](Function);
  });
  it("must have buf property", function() {
    expect(each).to.have.property("buf");
    return expect(each.buf).to.be.an["instanceof"](Function);
  });
  return it("must have factory property", function() {
    expect(each).to.have.property("factory");
    return expect(each.factory).to.be.an["instanceof"](Function);
  });
});

_ref1 = [bufferMode, objectMode];
_fn = function(mode) {
  return describe(mode.desc, function() {
    beforeEach(mode.before(each));
    afterEach(mode.after);
    it("must return an instanceof Transform", function(done) {
      return this.streamsArray.map((function(_this) {
        return function(stream, i) {
          expect(stream).to.be.an["instanceof"](Transform);
          if (i === _this.streamsArray.length - 1) {
            return done();
          }
        };
      })(this));
    });
    it("must return a noop stream if called without arguments", function(done) {
      this.noop.pipe(this.thr((function(_this) {
        return function(c, e, n) {
          expect(c).to.be.equal(_this.data1);
          return done();
        };
      })(this)));
      return this.noop.write(this.data1);
    });
    it("must pass data through stream unchanged", function(done) {
      var cache, defer;
      cache = [];
      defer = new Deferred();
      defer.then((function(_this) {
        return function() {
          return cache.map(function(spy, i) {
            expect(spy).to.have.been.calledWith(_this.data1);
            expect(spy).to.have.been.calledOnce;
            if (i === cache.length - 1) {
              return done();
            }
          });
        };
      })(this))["catch"](done);
      return this.streamsArray.map((function(_this) {
        return function(stream, i) {
          stream.write(_this.data1);
          cache.push(stream.spy);
          if (i === _this.streamsArray.length - 1) {
            return defer.resolve();
          }
        };
      })(this));
    });
    it("must be able to re-use the same stream multiple times", function(done) {
      var cache, defer;
      cache = [];
      defer = new Deferred();
      defer.then((function(_this) {
        return function() {
          return cache.map(function(v, i) {
            expect(v.spy).to.have.been.calledWith(v.data);
            expect(v.spy).to.have.callCount(_this.dataArray.length);
            if (i === cache.length - 1) {
              return done();
            }
          });
        };
      })(this))["catch"](done);
      return this.streamsArray.map((function(_this) {
        return function(stream, i) {
          return _this.dataArray.map(function(data, j) {
            stream.write(data);
            cache.push({
              spy: stream.spy,
              data: data
            });
            if (i === _this.streamsArray.length - 1 && j === _this.dataArray.length - 1) {
              return defer.resolve();
            }
          });
        };
      })(this));
    });
    return it("must pass data down stream multiple times", function(done) {
      var cache, defer, lastSpy;
      cache = [];
      lastSpy = this.streamsArray.slice(-1)[0].spy;
      defer = new Deferred();
      defer.then((function(_this) {
        return function() {
          expect(lastSpy).to.have.callCount(_this.dataArray.length);
          return _this.dataArray.map(function(data, i) {
            expect(lastSpy).to.have.been.calledWith(data);
            if (i === _this.dataArray.length - 1) {
              return done();
            }
          });
        };
      })(this))["catch"](done);
      this.noop.pipe(this.streamsArray[0]);
      return this.streamsArray.map((function(_this) {
        return function(stream, i) {
          if (i === _this.streamsArray.length - 1) {
            return _this.dataArray.map(function(data, j) {
              _this.noop.write(data);
              if (j === _this.dataArray.length - 1) {
                return defer.resolve();
              }
            });
          }
          return stream.pipe(_this.streamsArray[i + 1]);
        };
      })(this));
    });
  });
};
for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
  mode = _ref1[_i];
  _fn(mode);
}
