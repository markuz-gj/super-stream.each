
/**
 * @author Markuz GJ
 * @license MIT
 * @description - gulpfile for super-stream.each
 */

var gulp = require('gulp')
, gutil = require('gulp-util')
, etc = require('etc-etc')

, SRC = './index.js'
, SPEC = './spec/index.coffee' 
, FIXTURE = './spec/fixture.coffee'
;

// require('string.prototype.repeat') // es6 shim


gulp.task("test:mocha", etc.mocha(SPEC))
gulp.task("test:istanbul", etc.istanbul(SPEC))
gulp.task('compile:docs', etc.jsdoc(SRC))

// gulp.task('test', ['test:mocha'])
gulp.task('test', ['test:istanbul'])

gulp.task('watch:etc', function(){
  gulp.watch([__filename, '../etc-etc/*.{js,coffee}'], etc.exit)
})

if (process.argv.slice(-1)[0] === 'watch') {
  gulp.task("server", ["test", "compile:docs"], etc.server({port: 8010}))
}

gulp.task("watch", ["server", "watch:etc"], function() {
  return gulp.watch([SRC, SPEC, FIXTURE], function(evt) {
    if (evt.type !== 'added') {
      gulp.start('test', 'compile:docs')
    }
  })
})

gulp.task("default", ["test"])
