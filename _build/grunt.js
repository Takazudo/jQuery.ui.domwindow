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
    watch: {
      files: [
        '../jquery.ui.domwindow.coffee'
      ],
      tasks: 'coffee notifyOK'
    },
    coffee: {
      '../jquery.ui.domwindow.js':  [
        '../jquery.ui.domwindow.coffee'
      ]
    }
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

  grunt.registerTask('default', 'coffee notifyOK');

};
