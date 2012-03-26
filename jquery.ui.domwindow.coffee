win = window
doc = document
$win = $(win)
$doc = $(doc)
round = Math.round

$dialog = null
$overlay = null

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
    @$el.add(@$bg).css
      width: $win.width()
      height: $win.height()
      top: $win.scrollTop()
      left: $win.scrollLeft()

  _eventify: ->
    if not ie6 then return @
    $win.bind 'resize scroll', => @_resize()
    @

  _showOverlayEl: (woSpinner) ->
    $.Deferred (defer) =>
      if @options.spinjs and not woSpinner
        wait(0).done => @_attachSpinjs()
      @$el.css 'display', 'block'
      cssTo = { opacity: 0 }
      animTo = { opacity: @options.maxopacity }
      ($.when @$bg.stop().css(cssTo).animate(animTo, 200)).done =>
        defer.resolve()
    .promise()
  _hideOverlayEl: ->
    $.Deferred (defer) =>
      animTo = { opacity: 0 }
      ($.when @$bg.stop().animate(animTo, 100)).done =>
        @$el.css 'display', 'none'
        @$spinner.show()
        defer.resolve()
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
    @$spinner.empty().hide()
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
  if $overlay then return $overlay
  $overlay = $.ui.hideoverlay.create(options).appendTo 'body'
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
        @_trigger 'open'
        if options?.callback then options.callback.apply @$el, [@$el]
      wait(0).done => @center()
      currentOpen.defer.resolve()

    dialogType = null
    if @options.ajaxdialog then dialogType = 'ajax'
    if @options.iframedialog then dialogType = 'iframe'
    if @options.iddialog then dialogType = 'id'
    if o?.ajaxdialog then dialogType = 'ajax'
    if o?.iframedialog then dialogType = 'iframe'
    if o?.iddialog then dialogType = 'id'

    w = o.width or @options.width
    h = o.height or @options.height
    @$el.css
      width: w
      height: h

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
        @$el.empty().append $('#' + src).html()
        complete()

    currentOpen.kill = -> currentOpen.killed = true
    currentOpen

  close: ->
    $.Deferred (defer) =>
      if not @_isOpen then return @
      @_currentOpen?.kill()
      @_isOpen = false
      @overlay?.hide()
      @$el.fadeOut 200, =>
        defer.resolve()
        @_trigger 'close'

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
      hoge
      <a href="#" class="apply-domwindow-close">close</a>
    </div>
  """
  $(src).domwindowdialog(options)

$.ui.domwindowdialog.setup = (options) ->
  if $dialog then return $dialog
  $dialog = $.ui.domwindowdialog.create options
  $dialog.appendTo 'body'
  overlayOptions = genOverlayOptions(options)
  $dialog.domwindowdialog 'setOverlay', $.ui.hideoverlay.setup(overlayOptions)
  domwindowApi = win.domwindowApi = new DomwindowApi $dialog
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
  o.height = $el.data('domwindowHeight') or null
  o.width = $el.data('domwindowWidth') or null

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
  open: ->
    (domwindowApi.open @_id, @options).defer.done =>
      @_trigger 'open', {}, { dialog: $dialog }
  close: ->
    domwindowApi.close().done =>
      @_trigger 'close'

