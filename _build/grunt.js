/**
 * grunt
 * This compiles coffee to js
 *
 * grunt: https://github.com/cowboy/grunt
 * CoffeeScript: http://coffeescript.org/
 * growlnotify: http://growl.info/extras.php#growlnotify
 */
module.exports = function(grunt){

  var proc = require('child_process');
  var log = grunt.log;

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
    min: {
      '../jquery.ui.domwindow.min.js': '../jquery.ui.domwindow.js'
    }
  });

  grunt.registerMultiTask('min', 'minify', function() {
    var done = this.async();
    var src = this.file.src;
    var dest = this.file.dest;
    var command = 'uglifyjs -o ' + dest + ' ' + src;
    var out = proc.exec(command, function(err, sout, serr){
      log.writeln('uglified.');
      done(true);
    });
  });

  grunt.registerMultiTask('coffee', 'compile CoffeeScripts', function() {
    var done = this.async();
    var srcs = this.file.src.join(' ');
    var dest = this.file.dest;
    var command = 'coffee --join ' + dest + ' --compile ' + srcs;
    var out = proc.exec(command, function(err, sout, serr){
      if(err || sout || serr){
        proc.exec("growlnotify -t 'COFFEE COMPILE ERROR!' -m '" + serr + "'");
        log.writeln('Scripts were failed to compile to ' + dest + '.');
        done(false);
      }else{
        log.writeln('Scripts in were compiled to ' + dest + '.');
        done(true);
      }
    });
  });

  grunt.registerTask('notifyOK', 'done!', function(){
    proc.exec("growlnotify -t 'grunt.js' -m '＼(^o^)／'");
  });

  grunt.registerTask('default', 'coffee concat notifyOK');

};
