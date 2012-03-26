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
      spinjs: true
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
        this.$spinner.hide();
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
      height: 500,
      width: 500,
      fixedMinY: 30,
      selector_open: '.apply-domwindow-open',
      selector_close: '.apply-domwindow-close',
      ajaxdialog: true,
      ajaxdialog_avoidcache: true,
      iframedialog: false,
      iddialog: false,
      overlay: true
    },
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
      if (!this.options.overlay) return this;
      this.$overlay = $overlay;
      this.overlay = $overlay.data('hideoverlay');
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
      if (this.options.height + 50 < viewportH()) {
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
      var o,
        _this = this;
      o = options;
      return $.Deferred(function(defer) {
        var complete, dialogType, _ref, _ref2, _ref3;
        complete = function() {
          _this.$el.fadeIn(200, function() {
            var _ref;
            if ((_ref = _this.overlay) != null) _ref.hideSpinner();
            return _this._trigger('open');
          });
          wait(0).done(function() {
            return _this.center();
          });
          return defer.resolve();
        };
        dialogType = null;
        if (_this.options.ajaxdialog) dialogType = 'ajax';
        if (_this.options.iframedialog) dialogType = 'iframe';
        if (_this.options.iddialog) dialogType = 'id';
        if (o != null ? o.ajaxdialog : void 0) dialogType = 'ajax';
        if (o != null ? o.iframedialog : void 0) dialogType = 'iframe';
        if (o != null ? o.iddialog : void 0) dialogType = 'id';
        switch (dialogType) {
          case 'ajax':
            if ((_ref = _this.overlay) != null) _ref.show();
            return (_this._ajaxGet(src)).done(function(data) {
              _this.$el.empty().append(data);
              return complete();
            });
          case 'iframe':
            if ((_ref2 = _this.overlay) != null) _ref2.show();
            _this.$el.empty().append(_this._createIframeSrc(src));
            return complete();
          case 'id':
            if ((_ref3 = _this.overlay) != null) _ref3.show();
            _this.$el.empty().append($('#' + src).html());
            return complete();
        }
      }).promise();
    },
    close: function() {
      var _ref,
        _this = this;
      if ((_ref = this.overlay) != null) _ref.hide();
      this.$el.fadeOut(200, function() {
        return _this._trigger('close');
      });
      return this;
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
      this.dialog.open.apply(this.dialog, args);
      return this;
    };

    DomwindowApi.prototype.close = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.dialog.close.apply(this.dialog, args);
      return this;
    };

    return DomwindowApi;

  })();

  $.widget('ui.domwindow', {
    options: {
      iddialog: true
    },
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
      domwindowApi.open(this._id, this.options);
      return this;
    },
    close: function() {
      domwindowApi.close();
      return this;
    }
  });

}).call(this);
