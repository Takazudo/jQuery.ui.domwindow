(function() {

  (function($, win) {
    return $(function() {
      var $testdiv, ns, wait;
      $testdiv = $('#testplaceholder');
      ns = win.domwindowNs;
      wait = function(time) {
        return $.Deferred(function(defer) {
          return setTimeout(function() {
            return defer.resolve();
          }, time);
        });
      };
      QUnit.testDone(function() {
        $.ui.domwindowdialog.destroy();
        return $.ui.hideoverlay.destroy();
      });
      test('ensure globals', function() {
        ok($.ui);
        ok($.ui.domwindowdialog);
        ok($.ui.domwindow);
        ok($.ui.hideoverlay);
        return ok(win.domwindowNs);
      });
      test('utils viewport', function() {
        var h, w, x, y;
        w = ns.viewportH();
        h = ns.viewportW();
        x = ns.offsetX();
        y = ns.offsetY();
        equal($.type(w), 'number', "viewportW: " + w);
        equal($.type(h), 'number', "viewportH: " + h);
        equal($.type(x), 'number', "offsetX: " + x);
        return equal($.type(y), 'number', "offsetY: " + y);
      });
      test('hideoverlay setup', function() {
        $.ui.hideoverlay.setup();
        return ok(ns.widgets.$overlay.size(), '$overlay found');
      });
      test('hideoverlay destroy', function() {
        $.ui.hideoverlay.setup();
        ok(ns.widgets.$overlay.size(), '$overlay found');
        $.ui.hideoverlay.destroy();
        return ok(!ns.widgets.$overlay, '$overlay was not found');
      });
      test('domwindowdialog setup', function() {
        $.ui.domwindowdialog.setup();
        ok(win.domwindowApi, 'api found');
        ok(ns.widgets.$dialog.size(), '$dialog found');
        return ok(ns.widgets.$overlay.size(), '$overlay found');
      });
      test('domwindowdialog destroy', function() {
        $.ui.domwindowdialog.setup();
        ok(win.domwindowApi, 'api found');
        ok(ns.widgets.$dialog.size(), '$dialog found');
        ok(ns.widgets.$overlay.size(), '$overlay found');
        $.ui.domwindowdialog.destroy();
        ok(!ns.widgets.$dialog, '$dialog was not found');
        return ok(ns.widgets.$overlay, '$overlay was still there');
      });
      test('domwindowdialog setup override', function() {
        var o;
        $.ui.domwindowdialog.setup({
          width: 100,
          height: 200
        });
        o = ns.widgets.$dialog.domwindowdialog('option');
        equal(o.width, 100, '1st setup - width');
        equal(o.height, 200, '1st setup - height');
        $.ui.domwindowdialog.setup({
          width: 300,
          height: 400
        });
        o = ns.widgets.$dialog.domwindowdialog('option');
        equal(o.width, 300, '2nd setup - width');
        return equal(o.height, 400, '2nd setup - height');
      });
      asyncTest('domwindowdialog events passed via open', function() {
        var $dialog, api;
        expect(8);
        $.ui.domwindowdialog.setup({
          ajaxdialog: true
        });
        api = win.domwindowApi;
        $dialog = ns.widgets.$dialog;
        return api.open('dialogfragment.html', {
          beforeopen: function(e, data) {
            ok(true, 'beforeopen');
            return equal(data.dialog[0], $dialog[0], 'beforeopen: dialog was passed');
          },
          afteropen: function(e, data) {
            ok(true, 'afteropen');
            equal(data.dialog[0], $dialog[0], 'afteropen: dialog was passed');
            return wait(0).done(function() {
              return api.close();
            });
          },
          beforeclose: function(e, data) {
            ok(true, 'beforeclose');
            return equal(data.dialog[0], $dialog[0], 'beforeclose: dialog was passed');
          },
          afterclose: function(e, data) {
            ok(true, 'afterclose');
            equal(data.dialog[0], $dialog[0], 'afterclose: dialog was passed');
            return start();
          }
        });
      });
      asyncTest('domwindowdialog events passed via setup', function() {
        var api;
        expect(4);
        $.ui.domwindowdialog.setup({
          ajaxdialog: true,
          beforeopen: function() {
            return ok(true, 'beforeopen');
          },
          afteropen: function() {
            ok(true, 'afteropen');
            return wait(0).done(function() {
              return api.close();
            });
          },
          beforeclose: function() {
            return ok(true, 'beforeclose');
          },
          afterclose: function() {
            ok(true, 'afterclose');
            return start();
          }
        });
        api = win.domwindowApi;
        return api.open('dialogfragment.html');
      });
      asyncTest('domwindowdialog events passed via setup ensure events are fired everytime', function() {
        var api;
        expect(13);
        $.ui.domwindowdialog.setup({
          ajaxdialog: true,
          beforeopen: function() {
            return ok(true, 'beforeopen');
          },
          afteropen: function() {
            ok(true, 'afteropen');
            return wait(0).done(function() {
              return api.close();
            });
          },
          beforeclose: function() {
            return ok(true, 'beforeclose');
          },
          afterclose: function() {
            return ok(true, 'afterclose');
          }
        });
        api = win.domwindowApi;
        return api.open('dialogfragment.html', {
          afterclose: function() {
            return api.open('dialogfragment.html', {
              afterclose: function() {
                return api.open('dialogfragment.html', {
                  afterclose: function() {
                    ok(true, 'everything worked');
                    return start();
                  }
                });
              }
            });
          }
        });
      });
      asyncTest('domwindowdialog events passed via close', function() {
        var api;
        expect(4);
        $.ui.domwindowdialog.setup({
          ajaxdialog: true
        });
        api = win.domwindowApi;
        return api.open('dialogfragment.html', {
          beforeopen: function() {
            return ok(true, 'beforeopen');
          },
          afteropen: function() {
            ok(true, 'afteropen');
            return wait(0).done(function() {
              return api.close({
                beforeclose: function() {
                  return ok(true, 'beforeclose');
                },
                afterclose: function() {
                  ok(true, 'afterclose');
                  return start();
                }
              });
            });
          }
        });
      });
      asyncTest('domwindowdialog events ensure complicated events are all fired', function() {
        var api, firstOpen, secondOpen;
        expect(15);
        $.ui.domwindowdialog.setup({
          ajaxdialog: true,
          beforeopen: function() {
            return ok(true, 'beforeopen - via setup');
          },
          afteropen: function() {
            return ok(true, 'afteropen - via setup');
          },
          beforeclose: function() {
            return ok(true, 'beforeclose - via setup');
          },
          afterclose: function() {
            return ok(true, 'afterclose - via setup');
          }
        });
        api = win.domwindowApi;
        firstOpen = function() {
          return api.open('dialogfragment.html', {
            beforeopen: function() {
              return ok(true, 'beforeopen - via open');
            },
            afteropen: function() {
              ok(true, 'afteropen - via open');
              return wait(0).done(function() {
                return api.close({
                  beforeclose: function() {
                    return ok(true, 'beforeclose - via close');
                  },
                  afterclose: function() {
                    ok(true, 'afterclose - via close');
                    return secondOpen();
                  }
                });
              });
            },
            beforeclose: function() {
              return ok(true, 'beforeclose - via open');
            },
            afterclose: function() {
              return ok(true, 'afterclose - via open');
            }
          });
        };
        secondOpen = function() {
          return api.open('dialogfragment.html', {
            afteropen: function() {
              return wait(0).done(function() {
                return api.close();
              });
            },
            afterclose: function() {
              ok(true, 'afterclose - via open');
              return start();
            }
          });
        };
        return firstOpen();
      });
      asyncTest('domwindowdialog ajaxdialog', function() {
        var api;
        expect(1);
        $.ui.domwindowdialog.setup({
          ajaxdialog: true
        });
        api = win.domwindowApi;
        return api.open('dialogfragment.html', {
          afteropen: function(e, data) {
            equal((data.dialog.find('.woot')).text(), 'woot', 'fetched html was in dialog');
            return wait(0).done(function() {
              return api.close();
            });
          },
          afterclose: function() {
            return start();
          }
        });
      });
      asyncTest('domwindowdialog iframedialog', function() {
        var api;
        expect(1);
        $.ui.domwindowdialog.setup({
          iframedialog: true
        });
        api = win.domwindowApi;
        return api.open('dialogfragment.html', {
          afteropen: function(e, data) {
            ok((data.dialog.find('iframe')).size(), 'iframe was in dialog');
            return wait(0).done(function() {
              return api.close();
            });
          },
          afterclose: function() {
            return start();
          }
        });
      });
      asyncTest('domwindowdialog iddialog', function() {
        var api;
        expect(1);
        $testdiv.html("<script type=\"text/x-dialogcontent\" id=\"foobar\"><i>foobar</i></script>");
        $.ui.domwindowdialog.setup({
          iddialog: true
        });
        api = win.domwindowApi;
        return api.open('foobar', {
          afteropen: function(e, data) {
            equal((data.dialog.find('i')).text(), 'foobar', 'fetched html was in dialog');
            return wait(0).done(function() {
              return api.close();
            });
          },
          afterclose: function() {
            $testdiv.empty();
            return start();
          }
        });
      });
      return asyncTest('domwindowdialog deferredopen', function() {
        var api;
        expect(2);
        $.ui.domwindowdialog.setup();
        api = win.domwindowApi;
        return api.open(function(defer) {
          return wait(0).done(function() {
            return defer.resolve('<div class="moo">moo<div>');
          });
        }, {
          afteropen: function(e, data) {
            ok(true, 'deferredopen worked');
            equal((data.dialog.find('.moo')).text(), 'moo', 'attached html was in dialog');
            return wait(0).done(function() {
              return api.close();
            });
          },
          afterclose: function() {
            return start();
          }
        });
      });
    });
  })(jQuery, this);

}).call(this);
