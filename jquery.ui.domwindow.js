(function() {
  var $win, ie6, resolveSilently;

  $win = $(window);

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

  $.widget('ui.hideoverlay', {
    options: {
      spinnersrc: null,
      maxopacity: 0.8,
      bgiframe: true
    },
    widgetEventPrefix: 'hideoverlay.',
    _active: false,
    _create: function() {
      this.$el = this.element;
      this.$spinner = $('.ui-hideoverlay-spinner', this.$el);
      this.$bg = $('.ui-hideoverlay-bg', this.$el);
      this._preloadSpinner();
      this._eventify();
      this._handleIE6();
      return this;
    },
    _handleIE6: function() {
      if (!ie6) return this;
      this._resize();
      if (this.options.bgiframe) {
        this.$el.bgiframe({
          opacity: false
        });
      }
      return this;
    },
    _resize: function() {
      if (!ie6) return this;
      return this.$el.css({
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
    _showOverlayEl: function() {
      var _this = this;
      return $.Deferred(function(defer) {
        var animTo, cssTo;
        cssTo = {
          opacity: 0,
          display: 'block'
        };
        animTo = {
          opacity: _this.options.maxopacity
        };
        return ($.when(_this.$el.stop().css(cssTo).animate(animTo, 200))).done(function() {
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
        return ($.when(_this.$el.stop().animate(animTo, 100))).done(function() {
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
        this.$spinner.show();
      }
      this._trigger('showstart');
      this._showDefer = this._showOverlayEl();
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
    }
  });

  $.ui.hideoverlay.create = function() {
    var src;
    src = "<div class=\"ui-hideoverlay\" id=\"domwindow-hideoverlay\">\n  <div class=\"ui-hideoverlay-bg\"></div>\n  <div class=\"ui-hideoverlay-spinner\"></div>\n</div>";
    return $(src).hideoverlay();
  };

  $.ui.hideoverlay.setup = function() {
    return $.ui.hideoverlay.create().appendTo('body');
  };

}).call(this);
