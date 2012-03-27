win = window
doc = document
$win = $(win)
$doc = $(doc)
round = Math.round

# share dialog and overlay in this plugin

widgets =
  $dialog: null
  $overlay: null

# only this can be accessed from outside

win.domwindowApi = domwindowApi = null


# ============================================================
# browser detection

ie6 = do ->
  $el = $('<div><!--[if IE 6]><i></i><![endif]--></div>')
  return if $el.find('i').size() then true else false


# ============================================================
# tiny utils

# deferred helper

resolveSilently = ->
  $.Deferred (defer) -> defer.resolve()

# handle viewport things

viewportH = -> win.innerHeight or doc.documentElement.clientHeight or doc.body.clientHeight
viewportW = -> win.innerWidth or doc.documentElement.clientWidth or doc.body.clientWidth
scrollOffsetH = -> win.pageYOffset or doc.documentElement.scrollTop or doc.body.scrollTop
scrollOffsetW = -> win.pageXOffset or doc.documentElement.scrollLeft or doc.body.scrollLeft

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
    spinjs: false
  widgetEventPrefix: 'hideoverlay.'

  _active: false

  _create: ->
    @$el = @element
    @$spinner = $('.ui-hideoverlay-spinner', @$el)
    if @options.spinjs then @$spinner.css 'background', 'none'
    @$bg = $('.ui-hideoverlay-bg', @$el)
    @_preloadSpinner()
    @_eventify()
    @_handleIE6()
    @

  _attachSpinjs: ->
    if not @_showDefer then return @
    if not @_spinning then return @
    spinopts = 
      color:'#fff'
      lines: 15
      length: 22
      radius: 40
    (new Spinner spinopts).spin(@$spinner[0])

  _handleIE6: ->
    if not ie6 then return @
    @_resize()
    if @options.bgiframe and $.fn.bgiframe
      @$el.bgiframe()
    @

  _resize: ->
    if not ie6 then return @
    w = $win.width()
    h = $win.height()
    @$el.css
      width: w
      height: h
      top: $win.scrollTop()
      left: $win.scrollLeft()
    @$bg.css
      width: w
      height: h

  _eventify: ->
    if not ie6 then return @
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

$.ui.hideoverlay.setup = (options) ->
  if widgets.$overlay then return widgets.$overlay
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

  setOverlay: ($overlay) ->
    if not @options.overlay then return @
    @$overlay = $overlay
    @overlay = $overlay.data 'hideoverlay'
    if @options.overlayclickclose
      @$overlay.bind 'click', => @close()
    @

  center: ->

    props = {}
    props.left = round( viewportW()/2 + scrollOffsetW() - round(@$el.outerWidth()/2) )

    setTopAbsolutely = =>
      props.top = round( viewportH()/2 + scrollOffsetH() - round(@$el.outerHeight()/2) )
    setTopFixedly = =>
      props.top = round( viewportH()/2 - round(@$el.outerHeight()/2) )

    # can't see left side if window was too samll
    if props.left < 0 then props.left = 0

    # if win height was enough, put the dialog to the center
    if @$el.innerHeight() + 50 < viewportH()
      if ie6
        props.position = 'absolute'
        setTopAbsolutely()
      else
        if props.left isnt 0
          props.position = 'fixed'
          setTopFixedly()
        # but win width was not enough, stop fixed
        else
          props.position = 'absolute'
          setTopAbsolutely()
  
    # if win height was not enough, put the dialog to the dialog absolutely
    # because the we can't see the bottom of the dialog with fixed
    else
      props.position = 'absolute'
      props.top = @options.fixedMinY + scrollOffsetH()
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
        if options?.callback then options.callback.apply @$el, [@$el]
        @_currentOpen = null
      wait(0).done => @center()
      currentOpen.defer.resolve()

    dialogType = null
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
      if $target.is(':ui-domwindow')
        o = $.extend {}, $target.domwindow('createApiOpenOptions'), o

    @_attachOneTimeEvents o, 'open', currentOpen

    w = o.width or @options.width
    h = o.height or @options.height
    @$el.css
      width: w
      height: h

    @_trigger 'beforeopen', {}, { dialog: @$el }

    switch dialogType
      when 'ajax'
        @overlay?.show()
        delay = @options.ajaxdialog_mindelay
        $.when((@_ajaxGet src), (wait delay)).done (args...) =>
          data = args[0][0]
          @$el.empty().append data
          complete()
      when 'iframe'
        @overlay?.show(true)
        @$el.empty().append @_createIframeSrc(src)
        complete()
      when 'id'
        @overlay?.show(true)
        @$el.empty().append $target.html()
        complete()

    currentOpen.kill = -> currentOpen.killed = true
    currentOpen

  close: (options) ->
    $.Deferred (defer) =>
      if not @_isOpen then return @
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
    <div class="ui-domwindowdialog">
      <a href="#" class="apply-domwindow-close">close</a>
    </div>
  """
  $(src).domwindowdialog(options)

$.ui.domwindowdialog.setup = (options) ->
  if widgets.$dialog then return widgets.$dialog
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
  if not options then return ret
  $.each $.ui.hideoverlay.prototype.options, (key) ->
    if options[key] isnt undefined
      ret[key] = options[key]
  ret

# mostly we need to open dialog via anchor or button or something

getInfoFromOpener = (el) ->
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
    $.ui.domwindowdialog.setup()
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
      beforeclose: (e, data) -> self._trigger 'beforeclose', e, data
      afterclose: (e, data) -> self._trigger 'afterclose', e, data
  createApiCloseOptions: ->
    self = @
    o = {}
    delete o.beforeclose
    delete o.afterclose
    $.extend o,
      beforeclose: (e, data) -> self._trigger 'beforeclose', e, data
      afterclose: (e, data) -> self._trigger 'afterclose', e, data
  open: ->
    domwindowApi.open @_id, @createApiOpenOptions()
  close: ->
    domwindowApi.close @createApiCloseOptions()


