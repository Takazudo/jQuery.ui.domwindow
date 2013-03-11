module.exports = (grunt) ->
  
  grunt.task.loadTasks 'gruntcomponents/tasks'
  grunt.task.loadNpmTasks 'grunt-contrib-coffee'
  grunt.task.loadNpmTasks 'grunt-contrib-watch'
  grunt.task.loadNpmTasks 'grunt-contrib-concat'
  grunt.task.loadNpmTasks 'grunt-contrib-uglify'

  grunt.initConfig

    pkg: grunt.file.readJSON('package.json')
    banner: """
/*! <%= pkg.name %> (<%= pkg.repository.url %>)
 * lastupdate: <%= grunt.template.today("yyyy-mm-dd") %>
 * version: <%= pkg.version %>
 * author: <%= pkg.author %>
 * License: MIT */

"""

    growl:

      ok:
        title: 'COMPLETE!!'
        msg: '＼(^o^)／'

    coffee:

      domwindow:
        src: [ 'jquery.ui.domwindow.coffee' ]
        dest: 'jquery.ui.domwindow.js'
      test:
        src: [ 'tests/qunit/test/test.coffee' ]
        dest: 'tests/qunit/test/test.js'

    concat:

      banner:
        options:
          banner: '<%= banner %>'
        src: [ '<%= coffee.domwindow.dest %>' ]
        dest: '<%= coffee.domwindow.dest %>'
        
    uglify:

      options:
        banner: '<%= banner %>'
      domwindow:
        src: '<%= concat.banner.dest %>'
        dest: 'jquery.ui.domwindow.min.js'

    watch:

      domwindow:
        files: [
          '<%= coffee.domwindow.src %>'
          '<%= coffee.test.src %>'
        ]
        tasks: [
          'default'
        ]

  grunt.registerTask 'default', [
    'coffee'
    'concat'
    'uglify'
    'growl:ok'
  ]

