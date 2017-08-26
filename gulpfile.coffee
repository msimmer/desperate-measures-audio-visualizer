gulp = require 'gulp'
coffee = require 'gulp-coffee'
# sass = require 'gulp-sass'
autoprefixer = require 'gulp-autoprefixer'
concat = require 'gulp-concat'
cssmin = require 'gulp-cssnano'
rename = require 'gulp-rename'
gutil = require 'gulp-util'
rev = '8fc178a0-8498-466a-9782-700459b52115'


gulp.task 'coffee', [], ->
    gulp.src('lib/*.coffee')
    .pipe(coffee({ bare: true }).on('error', (err) ->
        console.log err.message
        console.log err.stack
    ))
    .pipe(gulp.dest('js/'))

gulp.task 'scripts', ['coffee'], ->
    gulp.src([
        'node_modules/jquery/dist/jquery.min.js'
        'js/media.js'
        'js/scripts.js'
    ])
    .pipe(gulp.dest('.tmp'))

gulp.task 'concat', ['scripts'], ->
    gulp.src([
        '.tmp/jquery.min.js'
        'vendor/jquery.fittext.js'
        '.tmp/*.js'
    ])
    .pipe(concat("main.#{rev}.js"))
    .pipe(gulp.dest('./'))


# gulp.task 'sass', [], ()->
#     gulp.src('sass/main.scss')
#     .pipe(sass())
#     .pipe(gulp.dest('.tmp'))

# gulp.task 'styles', ['sass'], ()->
#     gulp.src('.tmp/main.css')
#     .pipe(autoprefixer('last 2 versions'))
#     .pipe(cssmin())
#     .pipe(rename("main.#{rev}.css"))
#     .pipe(gulp.dest('./'))


gulp.task 'default', ['watch'], ()->

gulp.task 'watch', [
    # 'styles'
    'concat'
], ->

    #livereload.listen()

    # Watch for livereoad
    gulp.watch([
        '*.js'
        '*.php'
        '*.css'
    ]).on 'change', (file) ->
        console.log file.path

    # Watch for autoprefix
    # gulp.watch 'sass/**/*.scss', ['styles'], ()->
    # Watch for Coffeescript
    gulp.watch 'lib/*.coffee', ['concat'], ()->

#gulp.task 'build', [], ()->
