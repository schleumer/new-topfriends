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

root = './public/'

gulp.task 'clean:scripts', (cb) -> del ['dist/js'], cb

gulp.task 'clean:stylesheet', (cb) -> del ['dist/css'], cb

gulp.task 'clean:templates', (cb) -> del [
  'dist/templates',
  'dist/layouts',
  'dist/index.html'], cb

gulp.task 'clean:files', (cb) -> del ['dist/fonts', 'dist/icons'], cb

gulp.task 'copy-fonts', ->
  gulp.src('./src/fonts/**/*', {base: './src/'})
    .pipe(watch('./src/fonts/**/*', {base: './src/'}))
    .pipe(gulp.dest('./dist/'))

gulp.task 'copy-icons', ->
  gulp.src('./src/icons/**/*', {base: './src/'})
    .pipe(watch('./src/icons/**/*', {base: './src/'}))
    .pipe(gulp.dest('./dist/'))

gulp.task 'ls', ->
  b = watchify(browserify("./src/livescript/popup.ls", watchify.args))
  b.transform('liveify')
  b.bundle()
    .on('error', notify.onError("Error compiling livescript! \n <%= error.message %>"))
    .pipe(source('popup.js'))
    .pipe(gulp.dest('./dist/js'))
    .pipe(notify(message: "Livescript compiled!", on-last: true))

gulp.task 'prepend-ls', ['ls'], ->
  gulp.src('./dist/js/app.js')
    .pipe(insert.prepend(fs.readFileSync('./src/helpers/app.js.banner').toString().replace(/\%version\%/g, (new Date()).getTime())))
    .pipe(gulp.dest(path.join(root, 'js')))

gulp.task 'injected-ls', ->
  b = watchify(browserify("./src/livescript/injected.ls", watchify.args))
  b.transform('liveify')
  b.bundle()
    .on('error', notify.onError("Error compiling livescript! \n <%= error.message %>"))
    .pipe(source('injected.js'))
    .pipe(gulp.dest('./dist/js'))
    .pipe(notify(message: "Livescript compiled!", on-last: true))

gulp.task 'templates', ->
  locals = {
    api_address: 'http://local.topfriends.biz:3000'
  }

  jadeTask = jade {locals: locals, pretty: true}

  jadeTask.on('error', notify.onError("Error compiling jade! \n <%= error.message %>"))

  gulp.src('./src/jade/**/*.jade')
    .pipe(jadeTask)
    .pipe(gulp.dest('./dist/'))
    .pipe(notify(message: "Jade compiled!", on-last: true))

gulp.task 'stylesheet', ->
  gulp.src(['./src/less/popup.less'], {base: './src/less/'})
    .pipe(plumber({errorHandler: notify.onError("Error compiling LESS \n <%= error.message %>")}))
    .pipe(less({paths: [path.join __dirname, 'dist', 'components']}))
    .pipe(gulp.dest('./dist/css'))
    .pipe(notify(message: "LESS compiled!", on-last: true))

gulp.task 'connect', [
  'templates'
], ->
  connect.server {
    root: 'dist'
    livereload: true
  }

# Watch stuffs

gulp.task 'popup-ls-watch', ->
  watch('src/livescript/**/*.ls', ['popup-ls'], -> 
    gulp.start('popup-ls'))

gulp.task 'background-ls-watch', ->
  watch('src/livescript/**/*.ls', ['background-ls', 'background-prepend'], -> 
    gulp.start(['background-ls', 'background-prepend']))

gulp.task 'injected-ls-watch', ->
  watch('src/livescript/**/*.ls', ['injected-ls'], -> 
    gulp.start('injected-ls'))

gulp.task 'stylesheet-watch', ['stylesheet'], ->
  watch('src/less/**/*.less', -> 
    gulp.start('stylesheet'))

gulp.task 'templates-watch', ['templates'], ->
  watch('src/jade/**/*.jade', -> 
    gulp.start('templates'))

gulp.task 'clean', [
  'clean:scripts',
  'clean:stylesheet',
  'clean:templates',
  'clean:files'
]

gulp.task 'default', [
  'popup-ls'
  'background-ls'
  'background-prepend'
  'injected-ls'
  'stylesheet'
  'templates'
  'popup-ls-watch'
  'background-ls-watch'
  'injected-ls-watch'
  'stylesheet-watch'
  'templates-watch'
  'copy-fonts'
  'copy-icons'
  'copy-manifest'
  'copy-locales'
]