(($, win, doc) ->

  $win = $(win)
  $doc = $(doc)
  round = Math.round

  # only these can be accessed from outside

  win.domwindowNs = ns = {}
  win.domwindowApi = domwindowApi = null

  # share dialog and overlay in this plugin

  widgets = ns.widgets =
    $dialog: null
    $overlay: null


  # ============================================================
  # handle position fixed problem

  ns.ie6 = do ->
    $el = $('<div><!--[if IE 6]><i></i><![endif]--></div>')
    return if $el.find('i').length then true else false

  # following block was from jQuery mobile.
  # https://github.com/jquery/jquery-mobile/blob/master/js/widgets/fixedToolbar.js
  
  # Browser detection! Weeee, here we go...
  # Unfortunately, position:fixed is costly, not to mention probably impossible, to feature-detect accurately.
  # Some tests exist, but they currently return false results in critical devices and browsers, which could lead to a broken experience.
  # Testing fixed positioning is also pretty obtrusive to page load, requiring injected elements and scrolling the window
  # The following function serves to rule out some popular browsers with known fixed-positioning issues
  # This is a plugin option like any other, so feel free to improve or overwrite it
  ns.isBlackListedMobile = `function() {

    var w = window,
      ua = navigator.userAgent,
      platform = navigator.platform,
      // Rendering engine is Webkit, and capture major version
      wkmatch = ua.match( /AppleWebKit\/([0-9]+)/ ),
      wkversion = !!wkmatch && wkmatch[ 1 ],
      ffmatch = ua.match( /Fennec\/([0-9]+)/ ),
      ffversion = !!ffmatch && ffmatch[ 1 ],
      operammobilematch = ua.match( /Opera Mobi\/([0-9]+)/ ),
      omversion = !!operammobilematch && operammobilematch[ 1 ];

    if(
      // iOS 4.3 and older : Platform is iPhone/Pad/Touch and Webkit version is less than 534 (ios5)
      ( ( platform.indexOf( "iPhone" ) > -1 || platform.indexOf( "iPad" ) > -1  || platform.indexOf( "iPod" ) > -1 ) && wkversion && wkversion < 534 ) ||
      // Opera Mini
      ( w.operamini && ({}).toString.call( w.operamini ) === "[object OperaMini]" ) ||
      ( operammobilematch && omversion < 7458 )	||
      //Android lte 2.1: Platform is Android and Webkit version is less than 533 (Android 2.2)
      ( ua.indexOf( "Android" ) > -1 && wkversion && wkversion < 533 ) ||
      // Firefox Mobile before 6.0 -
      ( ffversion && ffversion < 6 ) ||
      // WebOS less than 3
      ( "palmGetResource" in window && wkversion && wkversion < 534 )	||
      // MeeGo
      ( ua.indexOf( "MeeGo" ) > -1 && ua.indexOf( "NokiaBrowser/8.5.0" ) > -1 ) ) {
      return true;
    }

    return false;

  }`

  # at last, can I use position fixed or not?
  ns.positionFixedUnavailable = ns.ie6 or ns.isBlackListedMobile()


  # ============================================================
  # tiny utils

  # deferred helper

  resolveSilently = ->
    $.Deferred (defer) -> defer.resolve()

  # handle viewport things

  viewportH = ns.viewportH = -> win.innerHeight or doc.documentElement.clientHeight or doc.body.clientHeight
  viewportW = ns.viewportW = -> win.innerWidth or doc.documentElement.clientWidth or doc.body.clientWidth
  offsetY = ns.offsetY = -> win.pageYOffset or doc.documentElement.scrollTop or doc.body.scrollTop
  offsetX = ns.offsetX = -> win.pageXOffset or doc.documentElement.scrollLeft or doc.body.scrollLeft

  # setTimeout wrapper

  wait = (time) ->
    $.Deferred (defer) ->
      setTimeout ->
        defer.resolve()
      , time

  # ============================================================
  # $.ui.hideoverlay
  # dark overlay over the page

  $.widget 'ui.hideoverlay',

    options:
      overlayfade: true
      spinnersrc: null
      maxopacity: 0.8
      bgiframe: false
      forceabsolute: ns.positionFixedUnavailable or false
      spinjs: false
      spinjs_options:
        color:'#fff'
        lines: 15
        length: 22
        radius: 40
    widgetEventPrefix: 'hideoverlay.'

    _active: false

    _create: ->
      @$el = @element
      @$spinner = $('.ui-hideoverlay-spinner', @$el)
      if @options.spinjs then @$spinner.css 'background', 'none'
      @$bg = $('.ui-hideoverlay-bg', @$el)
      @_preloadSpinner()
      @_eventify()
      @_handleLegacy()
      @

    _attachSpinjs: ->
      if not @_showDefer then return @
      if not @_spinning then return @
      (new Spinner @options.spinjs_options).spin(@$spinner[0])

    _handleLegacy: ->
      return @ unless @options.forceabsolute
      @$el.css 'position', 'absolute'
      @_resize()
      if @options.bgiframe and $.fn.bgiframe
        @$el.bgiframe()
      @

    _resize: ->
      return @ unless @options.forceabsolute
      w = viewportW()
      h = viewportH()
      @$el.css
        width: w
        height: h
        top: $win.scrollTop()
        left: $win.scrollLeft()
      @$bg.css
        width: w
        height: h

    _eventify: ->
      return @ unless @options.forceabsolute
      $win.bind 'resize scroll', => @_resize()
      @

    _showOverlayEl: (woSpinner) ->
      $.Deferred (defer) =>
        @$spinner.hide()
        @$el.css 'display', 'block'
        cssTo = { opacity: 0 }
        animTo = { opacity: @options.maxopacity }
        if @options.overlayfade
          ($.when @$bg.stop().css(cssTo).animate(animTo, 200)).done =>
            if not woSpinner
              if @options.spinjs
                @$spinner.show()
                @_attachSpinjs()
              @$spinner.hide().fadeIn()
            defer.resolve()
        else
          @$bg.css(animTo)
          if not woSpinner
            if @options.spinjs
              @$spinner.show()
              @_attachSpinjs()
            @$spinner.show()
          defer.resolve()
      .promise()

    _hideOverlayEl: ->
      $.Deferred (defer) =>
        animTo = { opacity: 0 }
        done = =>
          @$el.css 'display', 'none'
          @$spinner.show()
          defer.resolve()
        if @options.overlayfade
          ($.when @$bg.stop().animate(animTo, 100)).done => done()
        else
          @$bg.css(animTo)
          done()
      .promise()

    _preloadSpinner: ->
      src = @options.spinnersrc
      if not src then return @
      (new Image).src = src
      @

    show: (woSpinner) ->
      if @_showDefer then return @._showDefer
      if @_active then return resolveSilently()
      @_active = true
      if woSpinner
        @hideSpinner()
      else
        @_spinning = true
        @$spinner.show()
      @_trigger 'showstart'
      @_showDefer = @_showOverlayEl(woSpinner)
      @_showDefer.done =>
        @_showDefer = null
        @_trigger 'showend'
      @_showDefer

    hide: ->
      if @_showDefer
        @_showDefer.done => @hide()
        return @
      if not @_active then return resolveSilently()
      @_active = false
      @_trigger 'hidestart'
      @_hideDefer = @_hideOverlayEl()
      @_hideDefer.done =>
        @_hideDefer = null
        @_trigger 'hideend'
      @_hideDefer

    hideSpinner: ->
      @_spinning = false
      @$spinner.stop().empty().hide()
      @

  $.ui.hideoverlay.create = (options) ->
    src = """
      <div class="ui-hideoverlay" id="domwindow-hideoverlay">
        <div class="ui-hideoverlay-bg"></div>
        <div class="ui-hideoverlay-spinner"></div>
      </div>
    """
    $(src).hideoverlay(options)

  $.ui.hideoverlay.destroy = (options) ->
    if not widgets.$overlay then return false
    widgets.$overlay.hideoverlay('destroy').remove()
    widgets.$overlay = null
    true

  $.ui.hideoverlay.setup = (options) ->
    $.ui.hideoverlay.destroy()
    $overlay = $.ui.hideoverlay.create(options).appendTo 'body'
    widgets.$overlay = $overlay
    $overlay


  # ============================================================
  # $.ui.domwindow
  # handles the dialog itself

  $.widget 'ui.domwindowdialog',

    options:
      spinjs: false
      height: 500
      width: 500
      fixedMinY: 30
      selector_open: '.apply-domwindow-open'
      selector_close: '.apply-domwindow-close'
      ajaxdialog: true
      ajaxdialog_avoidcache: true
      ajaxdialog_mindelay: 300
      iframedialog: false
      iddialog: false
      overlay: true
      overlayclickclose: true
      forceabsolute: ns.positionFixedUnavailable or false
    widgetEventPrefix: 'domwindowdialog.'

    _create: ->
      @$el = @element
      @$el.css
        width: @options.width
        height: @options.height
      @_eventify()
      @

    _eventify: ->
      self = @
      $doc.on 'click', @options.selector_open, (e) ->
        e.preventDefault()
        info = getInfoFromOpener @
        self.open.apply self, info
      $doc.on 'click', @options.selector_close, (e) =>
        e.preventDefault()
        @close()
      $win.on 'resize', =>
        @center()
      @

    _appendFetchedData: (html) ->
      @$el.empty().append html
      @

    setOverlay: ($overlay) ->
      if not @options.overlay then return @
      @$overlay = $overlay
      @overlay = $overlay.data 'hideoverlay'
      if @options.overlayclickclose
        @$overlay.bind 'click', => @close()
      @

    center: ->

      props = {}

      elH = @$el.outerHeight()
      elW = @$el.outerWidth()
      vpW = viewportW()
      vpH = viewportH()
      offY = offsetY()
      offX = offsetX()

      isLeftOver = vpW < elW
      isBottomOver = vpH < elH + 50

      if isLeftOver
        props.left = 0 # bring it back to 0
        if isBottomOver
          # when wide and tall - fit to the left top corner
          props.position = 'absolute'
          props.top = @options.fixedMinY + offY
        else
          # when wide - fit to the left edge
          props.position = 'absolute'
          props.top = round(vpH/2) - round(elH/2) + offY
      else
        if isBottomOver
          # when tall - fit to the top edge
          props.position = 'absolute'
          props.top = @options.fixedMinY + offY
          props.left = round(vpW/2) - round(elW/2) + offX
        else
          # when small - put the very center
          props.top = round(vpH/2) - round(elH/2)
          props.left = round(vpW/2) - round(elW/2)
          if @options.forceabsolute
            props.position = 'absolute'
            props.top += offY
            props.left += offX
          else
            props.position = 'fixed'

      @$el.css props

      @

    open: (src, options) ->

      o = options
      @_isOpen = true

      @_currentOpen = currentOpen = {}
      currentOpen.defer = $.Deferred()

      complete = =>
        if currentOpen.killed then return
        @$el.fadeIn 200, =>
          @overlay?.hideSpinner()
          @_trigger 'afteropen', {}, { dialog: @$el }
          @_currentOpen = null
        wait(0).done => @center()
        currentOpen.defer.resolve()

      dialogType = null
      if $.isFunction(src)
        dialogType = 'deferred'
      else
        if src.indexOf('#') is 0
          dialogType = 'id'
          src = src.replace /^#/, ''
        else
          if @options.ajaxdialog then dialogType = 'ajax'
          if @options.iframedialog then dialogType = 'iframe'
          if @options.iddialog then dialogType = 'id'
          if o?.ajaxdialog then dialogType = 'ajax'
          if o?.iframedialog then dialogType = 'iframe'
          if o?.iddialog then dialogType = 'id'

      # if domwindow widget was attached to the target,
      # invoke its events when the dialog was opened or closed.
      if (dialogType is 'id')
        $target = $('#' + src)
        @$lastIdTarget = $target # store target to know close events
        if $target.is(':ui-domwindow')
          o = $.extend {}, $target.domwindow('createApiOpenOptions'), o
        else
          @$lastIdTarget = null
      else
        @$lastIdTarget = null

      @_attachOneTimeEvents o, 'open', currentOpen

      w = o?.width or @options.width
      h = o?.height or @options.height
      @$el.css
        width: w
        height: h

      @_trigger 'beforeopen', {}, { dialog: @$el }

      delay = @options.ajaxdialog_mindelay

      switch dialogType
        when 'deferred'
          @overlay?.show()
          defer = $.Deferred()
          src.apply @, [defer]
          $.when(defer, (wait delay)).done (data) =>
            @_appendFetchedData data
            complete()
        when 'ajax'
          @overlay?.show()
          $.when((@_ajaxGet src), (wait delay)).done (args...) =>
            data = args[0][0]
            @_appendFetchedData data
            complete()
        when 'iframe'
          @overlay?.show(true)
          @$el.empty().append @_createIframeSrc(src)
          complete()
        when 'id'
          @overlay?.show(true)
          @_appendFetchedData $target.html()
          complete()

      currentOpen.kill = -> currentOpen.killed = true
      currentOpen

    close: (options) ->
      $.Deferred (defer) =>
        if not @_isOpen then return @
        if @$lastIdTarget
          options = $.extend {}, options, @$lastIdTarget.domwindow('createApiCloseOptions')
        @_attachOneTimeEvents options, 'close'
        @_currentOpen?.kill()
        @_isOpen = false
        @_trigger 'beforeclose', {}, { dialog: @$el }
        wait(0).done =>
          @overlay?.hide()
          @$el.fadeOut 200, =>
            defer.resolve()
            @_trigger 'afterclose', {}, { dialog: @$el }

    _attachOneTimeEvents: (localOptions, command, currentOpen) ->
      if not localOptions then return @
      events = ['beforeclose', 'afterclose']
      if command is 'open'
        $.merge events, ['beforeopen', 'afteropen']
      $.each events, (i, ev) =>
        if localOptions[ev]
          @$el.one "#{@widgetEventPrefix}#{ev}", (args...) ->
            if currentOpen?.killed then return
            localOptions[ev].apply @$el, args
      @

    _ajaxGet: (url) ->
      options =
        url: url
        dataType: 'text'
      if @options.ajaxdialog_avoidcache
        options.cache = false
      $.ajax options

    _createIframeSrc: (url) ->
      name = genUniqId()
      """
        <iframe
          frameborder="0" hspace="0" wspace="0" src="#{url}" name="#{name}"
          style="width:100%; height:100%; border:none; background-color:#fff"
        ></iframe>
      """

  $.ui.domwindowdialog.create = (options) ->
    src = """
      <div class="ui-domwindowdialog"></div>
    """
    $(src).domwindowdialog(options)

  $.ui.domwindowdialog.destroy = ->
    if not widgets.$dialog then return false
    widgets.$dialog.domwindowdialog('destroy').remove()
    widgets.$dialog = null
    true

  $.ui.domwindowdialog.setup = (options) ->
    $.ui.domwindowdialog.destroy()
    $dialog = $.ui.domwindowdialog.create options
    $dialog.appendTo 'body'
    overlayOptions = genOverlayOptions(options)
    $dialog.domwindowdialog 'setOverlay', $.ui.hideoverlay.setup(overlayOptions)
    domwindowApi = win.domwindowApi = new DomwindowApi $dialog
    widgets.$dialog = $dialog
    $dialog


  # ============================================================
  # widget helpers

  # narrowdown overlay options

  genOverlayOptions = (options) ->
    ret = {}
    return ret unless options
    $.each $.ui.hideoverlay.prototype.options, (key) ->
      if options[key] isnt undefined
        ret[key] = options[key]
    ret

  # mostly we need to open dialog via anchor or button or something

  getInfoFromOpener = ns.getInfoFromOpener = (el) ->
    $el = $(el)
    ret = []

    src = $el.data('domwindowUrl') or $el.data('domwindowId')
    if not src then src = $el.attr('href').replace(/^#/,'')
    ret.push src

    o = {}
    if $el.data('domwindowAjaxdialog') then o.ajaxdialog = true
    if $el.data('domwindowIframedialog') then o.iframedialog = true
    if $el.data('domwindowIddialog') then o.iddialog = true
    do ->
      h = $el.data('domwindowHeight')
      if h then o.height = h
    do ->
      w = $el.data('domwindowWidth')
      if w then o.width = w

    ret.push o
    ret

  genUniqId = -> "domwindow-uniqid-#{Math.round(Math.random()*1000)}"

  # DomwindowApi will be attached to window.domwindowApi.
  # is a facade to domwindowdialog

  class DomwindowApi
    constructor: (@$dialog) ->
      @dialog = @$dialog.data 'domwindowdialog' # widget instance
    open: (args...) ->
      @dialog.open.apply @dialog, args
    close: (args...) ->
      @dialog.close.apply @dialog, args


  # ============================================================
  # $.ui.domwindow
  # jQuery.ui.dialog widget style

  $.widget 'ui.domwindow',
    options:
      iddialog: true
    widgetEventPrefix: 'domwindow.'
    _create: ->
      @$el = @element
      @_id = @$el.attr('id') or do =>
        id = genUniqId()
        @$el.attr 'id', id
        id
      @
    createApiOpenOptions: ->
      self = @
      o = $.extend {}, @options
      delete o.beforeopen
      delete o.afteropen
      delete o.beforeclose
      delete o.afterclose
      $.extend o,
        beforeopen: (e, data) -> self._trigger 'beforeopen', e, data
        afteropen: (e, data) -> self._trigger 'afteropen', e, data
    createApiCloseOptions: ->
      self = @
      o = {}
      delete o.beforeopen
      delete o.afteropen
      delete o.beforeclose
      delete o.afterclose
      $.extend o,
        beforeclose: (e, data) -> self._trigger 'beforeclose', e, data
        afterclose: (e, data) -> self._trigger 'afterclose', e, data
    open: ->
      domwindowApi.open @_id, @createApiOpenOptions()
    close: ->
      domwindowApi.close()

) jQuery, @, @document
