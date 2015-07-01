gulp = require 'gulp'
browserify = require 'browserify'
gutil = require 'gulp-util'
sourcemaps = require 'gulp-sourcemaps'
transform = require 'vinyl-transform'
uglify = require 'gulp-uglify'
jade = require 'gulp-jade'
watch = require 'gulp-watch'
watchify = require 'watchify'
del = require 'del'
concat = require 'gulp-concat'
less = require 'gulp-less'
path = require 'path'
gulpLiveScript = require 'gulp-livescript'
merge = require 'merge-stream'
streamqueue = require 'streamqueue'
source = require 'vinyl-source-stream'
fs = require 'fs'
plumber = require 'gulp-plumber'
notify = require 'gulp-notify'
changed = require 'gulp-changed'
insert = require 'gulp-insert'
replace = require 'gulp-replace'
closure-compiler = require 'gulp-closure-compiler'

root = './public/'

gulp.task 'clean:scripts', (cb) -> del [path.join(root, 'js')], cb

gulp.task 'clean:stylesheet', (cb) -> del [path.join(root, 'css')], cb

gulp.task 'clean:templates', (cb) -> del [
  path.join(root, 'templates'),
  path.join(root, 'layouts'),
  path.join(root, 'index.html')], cb

gulp.task 'clean:files', (cb) -> del [path.join(root, 'fonts'), path.join(root, 'icons')], cb

gulp.task 'copy-fonts', ->
  gulp.src('./frontend/fonts/**/*', {base: './frontend/'})
    .pipe(watch('./frontend/fonts/**/*', {base: './frontend/'}))
    .pipe(gulp.dest(root))

gulp.task 'copy-icons', ->
  gulp.src(['./frontend/icons/**/*', './frontend/favicon.ico'], {base: './frontend/'})
    .pipe(watch('./frontend/icons/**/*', {base: './frontend/'}))
    .pipe(gulp.dest(root))

gulp.task 'copy-images', ->
  gulp.src('./frontend/images/**/*', {base: './frontend/'})
    .pipe(watch('./frontend/images/**/*', {base: './frontend/'}))
    .pipe(gulp.dest(root))

gulp.task 'ls', ->
  b = watchify(browserify("./frontend/livescript/app.ls", watchify.args))
  b.transform('liveify')
  b.bundle()
    .on('error', notify.onError("Error compiling livescript! \n <%= error.message %>"))
    .pipe(source('app.js'))
    .pipe(gulp.dest(path.join(root, 'js')))
    .pipe(notify(message: "Livescript compiled!", on-last: true))

gulp.task 'prepend-ls', ['ls'], ->
  gulp.src(path.join(root, 'js/app.js'))
    .pipe(insert.prepend(fs.readFileSync('./frontend/helpers/app.js.banner').toString().replace(/\%version\%/g, (new Date()).getTime())))
    .pipe(gulp.dest(path.join(root, 'js')))

gulp.task 'closure-compiler', ['ls', 'prepend-ls'], ->
  gulp.src('./public/js/app.js')
    .pipe(closure-compiler({
      compilerPath: './node_modules/closurecompiler/compiler/compiler.jar',
      fileName: './public/js/app.gcc.js',
      compilerFlags: {
        language_in: 'ECMASCRIPT5_STRICT'
      }
    }))
    .pipe(gulp.dest('dist'))

gulp.task 'uglify', ['ls', 'prepend-ls'], ->
  gulp.src './public/js/app.js'
    .pipe uglify!
    .pipe gulp.dest './public/js/'

gulp.task 'templates', ->
  locals = {
    DEV: if process.env["DEV"] then true else false
    version: new Date().get-time!
  }

  jadeTask = jade {locals: locals, pretty: true}

  jadeTask.on('error', notify.onError("Error compiling jade! \n <%= error.message %>"))

  gulp.src('./frontend/jade/**/*.jade')
    .pipe(jadeTask)
    .pipe(gulp.dest(root))
    .pipe(notify(message: "Jade compiled!", on-last: true))

gulp.task 'stylesheet', ->
  gulp.src(['./frontend/less/main.less'], {base: './frontend/less/'})
    .pipe(plumber({errorHandler: notify.onError("Error compiling LESS \n <%= error.message %>")}))
    .pipe(less({paths: [path.join root, 'components']}))
    .pipe(gulp.dest(path.join(root, 'css')))
    .pipe(notify(message: "LESS compiled!", on-last: true))



# Watch stuffs

gulp.task 'ls-watch', ->
  watch('frontend/livescript/**/*.ls', ['ls', 'prepend-ls'], -> 
    gulp.start(['ls', 'prepend-ls']))

gulp.task 'stylesheet-watch', ['stylesheet'], ->
  watch('frontend/less/**/*.less', -> 
    gulp.start('stylesheet'))

gulp.task 'templates-watch', ['templates'], ->
  watch('frontend/jade/**/*.jade', -> 
    gulp.start('templates'))

gulp.task 'images-watch', ['copy-images'], ->
  watch('frontend/images/**/*', -> 
    gulp.start('copy-images'))

gulp.task 'clean', [
  'clean:scripts',
  'clean:stylesheet',
  'clean:templates',
  'clean:files'
]

gulp.task 'default', [
  'ls'
  'prepend-ls'
  'stylesheet'
  'templates'
  'ls-watch'
  'stylesheet-watch'
  'templates-watch'
  'copy-fonts'
  'copy-icons'
  'copy-images'
  'images-watch'
]

gulp.task 'prod', [
  'ls'
  'prepend-ls'
  #'closure-compiler',
  'stylesheet'
  #'stylesheet-uglify'
  #'prod-templates'
  'copy-fonts'
  'copy-icons'
  'copy-images'
  'uglify'
]
