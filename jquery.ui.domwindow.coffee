$win = $(window)

# ============================================================
# browser detection

ie6 = do ->
  $el = $('<div><!--[if IE 6]><i></i><![endif]--></div>')
  return if $el.find('i').size() then true else false

# ============================================================
# tiny utils

resolveSilently = ->
  $.Deferred (defer) -> defer.resolve()

# ============================================================
# $.ui.hideoverlay

$.widget 'ui.hideoverlay',

  options:
    spinnersrc: null
    maxopacity: 0.8
    bgiframe: false
  widgetEventPrefix: 'hideoverlay.'

  _active: false

  _create: ->
    @$el = @element
    @$spinner = $('.ui-hideoverlay-spinner', @$el)
    @$bg = $('.ui-hideoverlay-bg', @$el)
    @_preloadSpinner()
    @_eventify()
    @_handleIE6()
    @

  _handleIE6: ->
    if not ie6 then return @
    @_resize()
    if @options.bgiframe and $.fn.bgiframe
      @$el.bgiframe
        opacity: false
    @

  _resize: ->
    if not ie6 then return @
    @$el.css
      width: $win.width()
      height: $win.height()
      top: $win.scrollTop()
      left: $win.scrollLeft()

  _eventify: ->
    if not ie6 then return @
    $win.bind 'resize scroll', => @_resize()
    @

  _showOverlayEl: ->
    $.Deferred (defer) =>
      cssTo = { opacity: 0, display: 'block' }
      animTo = { opacity: @options.maxopacity }
      ($.when @$el.stop().css(cssTo).animate(animTo, 200)).done =>
        defer.resolve()
    .promise()
  _hideOverlayEl: ->
    $.Deferred (defer) =>
      animTo = { opacity: 0 }
      ($.when @$el.stop().animate(animTo, 100)).done =>
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
      @$spinner.hide()
    else
      @$spinner.show()
    @_trigger 'showstart'
    @_showDefer = @_showOverlayEl()
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

$.ui.hideoverlay.create = ->
  src = """
    <div class="ui-hideoverlay" id="domwindow-hideoverlay">
      <div class="ui-hideoverlay-bg"></div>
      <div class="ui-hideoverlay-spinner"></div>
    </div>
  """
  $(src).hideoverlay()

$.ui.hideoverlay.setup = ->
  $.ui.hideoverlay.create().appendTo 'body'
