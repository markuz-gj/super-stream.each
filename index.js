
/**
  * @module each
  * @author Markuz GJ 
  * @license MIT
  * @readme # Each
  * @description 
  *
  * [![NPM version](https://badge.fury.io/js/super-stream.each.png)](https://npmjs.org/package/super-stream.each)
  * [![Build Status](https://travis-ci.org/markuz-gj/super-stream.each.png?branch=master)](https://travis-ci.org/markuz-gj/super-stream.each)
  * [![Coverage Status](https://coveralls.io/repos/markuz-gj/super-stream.each/badge.png?branch=master)](https://coveralls.io/r/markuz-gj/super-stream.each?branch=master)
  * [![Dependency Status](https://david-dm.org/markuz-gj/super-stream.each.png)](https://david-dm.org/markuz-gj/super-stream.each)
  * [![devDependency Status](https://david-dm.org/markuz-gj/super-stream.each/dev-status.png)](https://david-dm.org/markuz-gj/super-stream.each#info=devDependencies)
  * [![MIT Licensed](http://img.shields.io/badge/license-MIT-blue.svg)](#license)
  *
  * ##\# Not ready yet
  * 
  * See also.  
  * [`super-stream`](https://github.com/markuz-gj/super-stream)  
  * [`super-stream.through`](https://github.com/markuz-gj/super-stream.through)  
  * [`super-stream.map`](https://github.com/markuz-gj/super-stream.map)  
  * [`super-stream.reduce`](https://github.com/markuz-gj/super-stream.reduce)  
  * [`super-stream.filter`](https://github.com/markuz-gj/super-stream.filter)  
  * [`super-stream.junction`](https://github.com/markuz-gj/super-stream.junction)  
  * [`super-stream.pipeline`](https://github.com/markuz-gj/super-stream.pipeline)  
  *
  * * * *
 */
var through = require("super-stream.through")
, isFunction = require("lodash.isfunction")
, defaults = require("lodash.defaults")
, isNull = require('lodash.isnull')
, Promise = Promise || require('es6-promise').Promise
;


/**
  * @instance
  * @param {Object=} options - Same options as seen [here](/jsdoc/module-each.html#factory)
  * @param {Function=} transform - `_transform` function as described [here](http://nodejs.org/docs/latest/api/stream.html#stream_class_stream_transform)
  * @param {Function=} flush - `_flush` function as described [here](http://nodejs.org/docs/latest/api/stream.html#stream_class_stream_transform) (same link as above)
  * @return {Transform} A instance of `Transform` stream from `readable-stream@1.0.x`
  * 
  * @readme 
  * 
  * ##\## _each([options,] [transformFn,] [flushFn]);_
  * 
  * ##\##\# this is how
  * 
  * @example
  *
  * ```javascript
  * 
  * var expect = require('chai').expect;
  * var each = require("super-stream.each")
  *
  * var streamA = each.obj(function(counter, enc, done){
  *   counter += 1;
  *   done(null, counter);
  * });
  * var streamB = each({objectMode: true}, function(counter, enc, done){
  *   counter += 1;
  *   done(null, counter);
  * });
  *
  * var each = each.factory({objectMode: true});
  *
  * streamA.pipe(streamB).pipe(each(function(counter, enc, done){
  *   expect(counter).to.be.equal(2);
  * }));
  * 
  * streamA.write(0);
  * 
  * ```
  *
  * @example
  * 
  * ```javascript
  * 
  * var streamA = each(function(chunk, enc, done){
  *   data = chunk.toString();
  *   done(null, new Buffer(data +'-'+ data));
  * });
  *
  * eachObj = each.factory({objectMode: true});
  * var streamB = eachObj.buf(function(chunk, enc, done){
  *   expect(chunk.toString()).to.be.equal('myData-myData');
  *   done();
  * });
  *  
  * streamA.pipe(streamB);
  * streamA.write(new Buffer('myData'));
  * 
  * ```
 */


function mainFactory (cfg) {
  return function each (options, transform, flush) {
    var stream, ctx
    ;
    if (isFunction(options)) {
      flush = transform
      transform = options
      options = cfg
    } else {
      options = defaults(options, cfg)
    }
    if (arguments.length === 0) {
      options = cfg
    }

    stream = through(options, transform, flush)
    stream._each = stream._transform

    ctx = Object.create(stream)
    stream._transform = function _transform (chunk, enc, _next) {
      var nextCalled = false
      , retValue
      , promiseStatus
      ;

      function next () {
        nextCalled = true
        _next.apply(_next, arguments)
      }

      function flush (value){
        next(null, value)
      }

      function forceThrow (err) {
        setImmediate(function(){
          next(err)
        })
      }

      retValue = this._each.call(ctx, chunk, enc, next)

 
      if (isNull(retValue)) return
      
      if (retValue instanceof Promise) {
        return retValue.then(flush).catch(forceThrow)
      }

      if (retValue instanceof Error) return next(retValue)
      
      if (!nextCalled) return next()
      
    }
    return stream
  }
}

/** 
  * @static
  * @param {Function=} transform - `_transform` function as described [here](http://nodejs.org/docs/latest/api/stream.html#stream_class_stream_transform)
  * @param {Function=} flush - `_flush` function as described [here](http://nodejs.org/docs/latest/api/stream.html#stream_class_stream_transform) (same link as above)
  * @return {Transform} A instance of `Transform` stream from `readable-stream@1.0.x`
  *
  * @readme 
  * 
  * ##\## _each.obj([transfromFn,] [flushFn])_
  *
  * @description 
  * 
  * It is a conveniece method for `each({objectMode: true}, transformFn, flushFn);`  
  * If called without arguments, returns a passthrough `Transform` 
  *
  * @example
  * 
  * ```javascript
  * var stream = each.obj(function(string, enc, done){
  *   expect(string).to.be.deep.equal({data: 'myData'});
  *   done();
  * });
  * stream.write({data: 'myData'});
  * ```
 */

function objFactory (cfg) {
  return function obj (options, transform, flush) {
    if (isFunction(options)) {
      flush = transform
      transform = options
      options = cfg
    } else {
      options = defaults(options, cfg)
    }
    if (arguments.length === 0) {
      options = cfg
    }

    options.objectMode = true
    return mainFactory(options)(options, transform, flush)
  }
}


/** 
  * @static
  * @param {Function=} transform - `_transform` function as described [here](http://nodejs.org/docs/latest/api/stream.html#stream_class_stream_transform)
  * @param {Function=} flush - `_flush` function as described [here](http://nodejs.org/docs/latest/api/stream.html#stream_class_stream_transform) (same link as above)
  * @return {Transform} A instance of `Transform` stream from `readable-stream@1.0.x`
  *
  * 
  * @readme 
  * 
  * ##\## _each.buf([transfromFn,] [flushFn])_
  *
  * @description 
  * It is a conveniece method for `each({objectMode: false}, transformFn, flushFn);`  
  * If called without arguments, returns a passthrough `Transform` 
  *
  * @example
  * 
  * ```javascript
  * // see the factory method.
  * var each = each.factory({objectMode: true});
  * var myData = new Buffer('my data');

  * var streamBuf = each.buf(function(chunk, enc, done){
  *   expect(chunk).to.be.equal(myData);
  *   expect(chunk).to.not.be.equal('my data');
  *   done();
  * });
  * streamBuf.write(myData);
  * ```
 */

function bufFactory (cfg) {
  return function buf (options, transform, flush) {
    if (isFunction(options)) {
      flush = transform
      transform = options
      options = cfg
    } else {
      options = defaults(options, cfg)
    }
    if (arguments.length === 0) {
      options = cfg
    }

    options.objectMode = false
    return mainFactory(options)(options, transform, flush)
  }
}


/** 
  * @static
  *
  * @param {Object=} options - Object passed to `stream.Transfrom` constructor as described [here](http://nodejs.org/docs/latest/api/stream.html#stream_new_stream_readable_options) and [here](http://nodejs.org/docs/latest/api/stream.html#stream_new_stream_duplex_options)
  * @param {Number=} [options.highWaterMark = 16kb]- The maximum number of bytes to store in the internal buffer before ceasing to read from the underlying resource.
  * @param {?String=} [options.encoding = null] -  If specified, then buffers will be decoded to strings using the specified encoding.
  * @param {Boolean=} [options.objectMode = false] - Whether this stream should behave as a stream of objects. Meaning that stream.read(n) returns a single value instead of a Buffer of size n.
  * @param {Boolean=} [options.allowHalfOpen = true] - If set to false, then the stream will automatically end the readable side when the writable side ends and vice versa.
  * @return {each} A `each` function with `options` pre-configured as default
  *
  * @readme 
  * 
  * ##\## _each.factory([options]);_
  *
  * @description 
  * 
  * A factory method for creating a custom `each` instance.  
  *
  * @example
  * 
  * ```javascript
  * var eachObj = each.factory({objectMode: true});
  *
  * var streamObj = eachObj(function(string, enc, done){
  *   expect(string).to.be.equal('my data');
  *   done();
  * });
  * streamObj.write('my data');
  * ```
  *
  * ```javascript
  * var myData = new Buffer('my data');
  * var eachBuf = each.factory({objectMode: false, highWaterMark: 1000*Math.pow(2,6)});
  *
  * var streamBuf = eachBuf(function(chunk, enc, done){
  *   expect(chunk).to.be.equal(myData);
  *   expect(chunk).to.not.be.equal('my data');
  *   done();
  * });
  * streamBuf.write(myData);
  * ```
 */

factory = function(cfg) {
  var fn
  ;
  cfg = cfg || {}

  fn = mainFactory(cfg)
  fn.obj = objFactory(cfg)
  fn.buf = bufFactory(cfg)
  fn.factory = factory
  return fn
};


/**
  * @description 
  * License
  * ---
  *
  * The MIT License (MIT)
  *
  * Copyright (c) 2014 Markuz GJ
  *
  * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to
  * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
  *
  * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  *
  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
  * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  *
  * [![NPM](https://nodei.co/npm/super-stream.each.png)](https://nodei.co/npm/super-stream.each/) [![NPM](https://nodei.co/npm-dl/super-stream.each.png)](https://nodei.co/npm/super-stream.each/)
 */
module.exports = factory()
