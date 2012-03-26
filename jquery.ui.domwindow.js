(function() {
  var $dialog, $doc, $overlay, $win, DomwindowApi, doc, domwindowApi, genUniqId, getInfoFromOpener, ie6, resolveSilently, round, scrollOffsetH, scrollOffsetW, viewportH, viewportW, wait, win,
    __slice = Array.prototype.slice;

  win = window;

  doc = document;

  $win = $(win);

  $doc = $(doc);

  round = Math.round;

  $dialog = null;

  $overlay = null;

  win.domwindowApi = domwindowApi = null;

  ie6 = (function() {
    var $el;
    $el = $('<div><!--[if IE 6]><i></i><![endif]--></div>');
    if ($el.find('i').size()) {
      return true;
    } else {
      return false;
    }
  })();

  resolveSilently = function() {
    return $.Deferred(function(defer) {
      return defer.resolve();
    });
  };

  viewportH = function() {
    return win.innerHeight || doc.documentElement.clientHeight || doc.body.clientHeight;
  };

  viewportW = function() {
    return win.innerWidth || doc.documentElement.clientWidth || doc.body.clientWidth;
  };

  scrollOffsetH = function() {
    return win.pageYOffset || doc.documentElement.scrollTop || doc.body.scrollTop;
  };

  scrollOffsetW = function() {
    return win.pageXOffset || doc.documentElement.scrollLeft || doc.body.scrollLeft;
  };

  wait = function(time) {
    return $.Deferred(function(defer) {
      return setTimeout(function() {
        return defer.resolve();
      }, time);
    });
  };

  $.widget('ui.hideoverlay', {
    options: {
      spinnersrc: null,
      maxopacity: 0.8,
      bgiframe: false,
      spinjs: false
    },
    widgetEventPrefix: 'hideoverlay.',
    _active: false,
    _create: function() {
      this.$el = this.element;
      this.$spinner = $('.ui-hideoverlay-spinner', this.$el);
      if (this.options.spinjs) this.$spinner.css('background', 'none');
      this.$bg = $('.ui-hideoverlay-bg', this.$el);
      this._preloadSpinner();
      this._eventify();
      this._handleIE6();
      return this;
    },
    _attachSpinjs: function() {
      var spinopts;
      if (!this._showDefer) return this;
      if (!this._spinning) return this;
      spinopts = {
        color: '#fff',
        lines: 15,
        length: 22,
        radius: 40
      };
      return (new Spinner(spinopts)).spin(this.$spinner[0]);
    },
    _handleIE6: function() {
      if (!ie6) return this;
      this._resize();
      if (this.options.bgiframe && $.fn.bgiframe) {
        this.$el.bgiframe({
          opacity: false
        });
      }
      return this;
    },
    _resize: function() {
      if (!ie6) return this;
      return this.$el.add(this.$bg).css({
        width: $win.width(),
        height: $win.height(),
        top: $win.scrollTop(),
        left: $win.scrollLeft()
      });
    },
    _eventify: function() {
      var _this = this;
      if (!ie6) return this;
      $win.bind('resize scroll', function() {
        return _this._resize();
      });
      return this;
    },
    _showOverlayEl: function(woSpinner) {
      var _this = this;
      return $.Deferred(function(defer) {
        var animTo, cssTo;
        if (_this.options.spinjs && !woSpinner) {
          wait(0).done(function() {
            return _this._attachSpinjs();
          });
        }
        _this.$el.css('display', 'block');
        cssTo = {
          opacity: 0
        };
        animTo = {
          opacity: _this.options.maxopacity
        };
        return ($.when(_this.$bg.stop().css(cssTo).animate(animTo, 200))).done(function() {
          return defer.resolve();
        });
      }).promise();
    },
    _hideOverlayEl: function() {
      var _this = this;
      return $.Deferred(function(defer) {
        var animTo;
        animTo = {
          opacity: 0
        };
        return ($.when(_this.$bg.stop().animate(animTo, 100))).done(function() {
          _this.$el.css('display', 'none');
          _this.$spinner.show();
          return defer.resolve();
        });
      }).promise();
    },
    _preloadSpinner: function() {
      var src;
      src = this.options.spinnersrc;
      if (!src) return this;
      (new Image).src = src;
      return this;
    },
    show: function(woSpinner) {
      var _this = this;
      if (this._showDefer) return this._showDefer;
      if (this._active) return resolveSilently();
      this._active = true;
      if (woSpinner) {
        this.hideSpinner();
      } else {
        this._spinning = true;
        this.$spinner.show();
      }
      this._trigger('showstart');
      this._showDefer = this._showOverlayEl(woSpinner);
      this._showDefer.done(function() {
        _this._showDefer = null;
        return _this._trigger('showend');
      });
      return this._showDefer;
    },
    hide: function() {
      var _this = this;
      if (this._showDefer) {
        this._showDefer.done(function() {
          return _this.hide();
        });
        return this;
      }
      if (!this._active) return resolveSilently();
      this._active = false;
      this._trigger('hidestart');
      this._hideDefer = this._hideOverlayEl();
      this._hideDefer.done(function() {
        _this._hideDefer = null;
        return _this._trigger('hideend');
      });
      return this._hideDefer;
    },
    hideSpinner: function() {
      this._spinning = false;
      this.$spinner.empty().hide();
      return this;
    }
  });

  $.ui.hideoverlay.create = function() {
    var src;
    src = "<div class=\"ui-hideoverlay\" id=\"domwindow-hideoverlay\">\n  <div class=\"ui-hideoverlay-bg\"></div>\n  <div class=\"ui-hideoverlay-spinner\"></div>\n</div>";
    return $(src).hideoverlay();
  };

  $.ui.hideoverlay.setup = function() {
    if ($overlay) return $overlay;
    $overlay = $.ui.hideoverlay.create().appendTo('body');
    return $overlay;
  };

  $.widget('ui.domwindowdialog', {
    options: {
      spinnersrc: null,
      height: 500,
      width: 500,
      fixedMinY: 30,
      selector_open: '.apply-domwindow-open',
      selector_close: '.apply-domwindow-close',
      ajaxdialog: true,
      ajaxdialog_avoidcache: true,
      ajaxdialog_mindelay: 300,
      iframedialog: false,
      iddialog: false,
      overlay: true
    },
    widgetEventPrefix: 'domwindowdialog.',
    _create: function() {
      this.$el = this.element;
      this.$el.css({
        width: this.options.width,
        height: this.options.height
      });
      this._eventify();
      return this;
    },
    _eventify: function() {
      var self,
        _this = this;
      self = this;
      $doc.on('click', this.options.selector_open, function(e) {
        var info;
        e.preventDefault();
        info = getInfoFromOpener(this);
        return self.open.apply(self, info);
      });
      $doc.on('click', this.options.selector_close, function(e) {
        e.preventDefault();
        return _this.close();
      });
      $win.on('resize', function() {
        return _this.center();
      });
      return this;
    },
    setOverlay: function($overlay) {
      var _this = this;
      if (!this.options.overlay) return this;
      this.$overlay = $overlay;
      this.overlay = $overlay.data('hideoverlay');
      this.$overlay.bind('click', function() {
        return _this.close();
      });
      return this;
    },
    center: function() {
      var props, setTopAbsolutely, setTopFixedly,
        _this = this;
      props = {};
      props.left = round(viewportW() / 2 + scrollOffsetW() - round(this.$el.outerWidth() / 2));
      setTopAbsolutely = function() {
        return props.top = round(viewportH() / 2 + scrollOffsetH() - round(_this.$el.outerHeight() / 2));
      };
      setTopFixedly = function() {
        return props.top = round(viewportH() / 2 - round(_this.$el.outerHeight() / 2));
      };
      if (props.left < 0) props.left = 0;
      if (this.$el.innerHeight() + 50 < viewportH()) {
        if (ie6) {
          props.position = 'absolute';
          setTopAbsolutely();
        } else {
          if (props.left !== 0) {
            props.position = 'fixed';
            setTopFixedly();
          } else {
            props.position = 'absolute';
            setTopAbsolutely();
          }
        }
      } else {
        props.position = 'absolute';
        props.top = this.options.fixedMinY + scrollOffsetH();
      }
      this.$el.css(props);
      return this;
    },
    open: function(src, options) {
      var complete, currentOpen, delay, dialogType, h, o, w, _ref, _ref2, _ref3,
        _this = this;
      o = options;
      this._isOpen = true;
      this._currentOpen = currentOpen = {};
      currentOpen.defer = $.Deferred();
      complete = function() {
        if (currentOpen.killed) return;
        _this.$el.fadeIn(200, function() {
          var _ref;
          if ((_ref = _this.overlay) != null) _ref.hideSpinner();
          return _this._trigger('open');
        });
        wait(0).done(function() {
          return _this.center();
        });
        return currentOpen.defer.resolve();
      };
      dialogType = null;
      if (this.options.ajaxdialog) dialogType = 'ajax';
      if (this.options.iframedialog) dialogType = 'iframe';
      if (this.options.iddialog) dialogType = 'id';
      if (o != null ? o.ajaxdialog : void 0) dialogType = 'ajax';
      if (o != null ? o.iframedialog : void 0) dialogType = 'iframe';
      if (o != null ? o.iddialog : void 0) dialogType = 'id';
      w = o.width || this.options.width;
      h = o.height || this.options.height;
      this.$el.css({
        width: w,
        height: h
      });
      switch (dialogType) {
        case 'ajax':
          if ((_ref = this.overlay) != null) _ref.show();
          delay = this.options.ajaxdialog_mindelay;
          $.when(this._ajaxGet(src), wait(delay)).done(function() {
            var args, data;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            data = args[0][0];
            _this.$el.empty().append(data);
            return complete();
          });
          break;
        case 'iframe':
          if ((_ref2 = this.overlay) != null) _ref2.show(true);
          this.$el.empty().append(this._createIframeSrc(src));
          complete();
          break;
        case 'id':
          if ((_ref3 = this.overlay) != null) _ref3.show(true);
          this.$el.empty().append($('#' + src).html());
          complete();
      }
      currentOpen.kill = function() {
        return currentOpen.killed = true;
      };
      return currentOpen;
    },
    close: function() {
      var _this = this;
      return $.Deferred(function(defer) {
        var _ref, _ref2;
        if (!_this._isOpen) return _this;
        if ((_ref = _this._currentOpen) != null) _ref.kill();
        _this._isOpen = false;
        if ((_ref2 = _this.overlay) != null) _ref2.hide();
        return _this.$el.fadeOut(200, function() {
          defer.resolve();
          return _this._trigger('close');
        });
      });
    },
    _ajaxGet: function(url) {
      var options;
      options = {
        url: url,
        dataType: 'text'
      };
      if (this.options.ajaxdialog_avoidcache) options.cache = false;
      return $.ajax(options);
    },
    _createIframeSrc: function(url) {
      var name;
      name = genUniqId();
      return "<iframe\n  frameborder=\"0\" hspace=\"0\" wspace=\"0\" src=\"" + url + "\" name=\"" + name + "\"\n  style=\"width:100%; height:100%; border:none; background-color:#fff\"\n></iframe>";
    }
  });

  $.ui.domwindowdialog.create = function(options) {
    var src;
    src = "<div class=\"ui-domwindowdialog\">\n  hoge\n  <a href=\"#\" class=\"apply-domwindow-close\">close</a>\n</div>";
    return $(src).domwindowdialog(options);
  };

  $.ui.domwindowdialog.setup = function(options) {
    if ($dialog) return $dialog;
    $dialog = $.ui.domwindowdialog.create(options);
    $dialog.appendTo('body');
    $dialog.domwindowdialog('setOverlay', $.ui.hideoverlay.setup());
    domwindowApi = win.domwindowApi = new DomwindowApi($dialog);
    return $dialog;
  };

  getInfoFromOpener = function(el) {
    var $el, o, ret, src;
    $el = $(el);
    ret = [];
    src = $el.data('domwindowUrl') || $el.data('domwindowId');
    if (!src) src = $el.attr('href').replace(/^#/, '');
    ret.push(src);
    o = {};
    if ($el.data('domwindowAjaxdialog')) o.ajaxdialog = true;
    if ($el.data('domwindowIframedialog')) o.iframedialog = true;
    if ($el.data('domwindowIddialog')) o.iddialog = true;
    o.height = $el.data('domwindowHeight') || null;
    o.width = $el.data('domwindowWidth') || null;
    ret.push(o);
    return ret;
  };

  genUniqId = function() {
    return "domwindow-uniqid-" + (Math.round(Math.random() * 1000));
  };

  DomwindowApi = (function() {

    function DomwindowApi($dialog) {
      this.$dialog = $dialog;
      this.dialog = this.$dialog.data('domwindowdialog');
    }

    DomwindowApi.prototype.open = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.dialog.open.apply(this.dialog, args);
    };

    DomwindowApi.prototype.close = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.dialog.close.apply(this.dialog, args);
    };

    return DomwindowApi;

  })();

  $.widget('ui.domwindow', {
    options: {
      iddialog: true
    },
    widgetEventPrefix: 'domwindow.',
    _create: function() {
      var _this = this;
      this.$el = this.element;
      $.ui.domwindowdialog.setup();
      this._id = this.$el.attr('id') || (function() {
        var id;
        id = genUniqId();
        _this.$el.attr('id', id);
        return id;
      })();
      return this;
    },
    open: function() {
      var _this = this;
      return (domwindowApi.open(this._id, this.options)).defer.done(function() {
        return _this._trigger('open', {}, {
          dialog: $dialog
        });
      });
    },
    close: function() {
      var _this = this;
      return domwindowApi.close().done(function() {
        return _this._trigger('close');
      });
    }
  });

}).call(this);
