/**
 * grunt
 * This compiles coffee to js
 *
 * grunt: https://github.com/cowboy/grunt
 */
module.exports = function(grunt){

  grunt.initConfig({
    pkg: '<json:info.json>',
    meta: {
      banner: '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
        ' <%= grunt.template.today("m/d/yyyy") %>\n' +
        ' <%= pkg.homepage ? "* " + pkg.homepage + "\n" : "" %>' +
        ' * Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
        ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */'
    },
    concat: {
      '../jquery.ui.domwindow.js': [ '<banner>', '../jquery.ui.domwindow.js' ]
    },
    watch: {
      files: [
        '../jquery.ui.domwindow.coffee',
        '../tests/qunit/test/test.coffee'
      ],
      tasks: 'coffee concat notifyOK'
    },
    coffee: {
      '../jquery.ui.domwindow.js':  [
        '../jquery.ui.domwindow.coffee'
      ],
      '../tests/qunit/test/test.js':  [
        '../tests/qunit/test/test.coffee'
      ]
    },
    uglify: {
      '../jquery.ui.domwindow.min.js': '../jquery.ui.domwindow.js'
    }
  });

  grunt.loadTasks('tasks');
  grunt.registerTask('default', 'coffee concat notifyOK');

};
