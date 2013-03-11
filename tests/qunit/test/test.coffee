(($, win) ->
  
  $ ->

    # for tests
    
    $testdiv = $('#testplaceholder')
    ns = win.domwindowNs

    # helpers
    
    wait = (time) ->
      $.Deferred (defer) ->
        setTimeout ->
          defer.resolve()
        , time

    # reset instances everytime
    
    QUnit.testDone ->
      $.ui.domwindowdialog.destroy()
      $.ui.hideoverlay.destroy()


    # main

    test 'ensure globals', ->

      ok $.ui
      ok $.ui.domwindowdialog
      ok $.ui.domwindow
      ok $.ui.hideoverlay
      ok win.domwindowNs


    test 'utils viewport', ->

      w = ns.viewportH()
      h = ns.viewportW()
      x = ns.offsetX()
      y = ns.offsetY()
      
      equal $.type(w), 'number', "viewportW: #{w}"
      equal $.type(h), 'number', "viewportH: #{h}"
      equal $.type(x), 'number', "offsetX: #{x}"
      equal $.type(y), 'number', "offsetY: #{y}"


    test 'hideoverlay setup', ->

      $.ui.hideoverlay.setup()
      ok ns.widgets.$overlay.size(), '$overlay found'


    test 'hideoverlay destroy', ->

      $.ui.hideoverlay.setup()
      ok ns.widgets.$overlay.size(), '$overlay found'
      $.ui.hideoverlay.destroy()
      ok not ns.widgets.$overlay, '$overlay was not found'


    asyncTest 'hideoverlay events', ->

      expect 4

      $overlay = $.ui.hideoverlay.setup
        showstart: ->
          ok true, 'showstart fired'
        showend: ->
          ok true, 'showend fired'
          wait(0).done -> $overlay.hideoverlay 'hide'
        hidestart: ->
          ok true, 'hidestart fired'
        hideend: ->
          ok true, 'showend fired'
          start()

      $overlay.hideoverlay 'show'


    test 'domwindowdialog setup', ->

      $.ui.domwindowdialog.setup()
      ok win.domwindowApi, 'api found'
      ok ns.widgets.$dialog.size(), '$dialog found'
      ok ns.widgets.$overlay.size(), '$overlay found'


    test 'domwindowdialog destroy', ->

      $.ui.domwindowdialog.setup()
      ok win.domwindowApi, 'api found'
      ok ns.widgets.$dialog.size(), '$dialog found'
      ok ns.widgets.$overlay.size(), '$overlay found'
      $.ui.domwindowdialog.destroy()
      ok not ns.widgets.$dialog, '$dialog was not found'
      ok ns.widgets.$overlay, '$overlay was still there'


    test 'domwindowdialog setup override', ->

      $.ui.domwindowdialog.setup
        width: 100
        height: 200
      o = ns.widgets.$dialog.domwindowdialog 'option'
      equal o.width, 100, '1st setup - width'
      equal o.height, 200, '1st setup - height'

      $.ui.domwindowdialog.setup
        width: 300
        height: 400
      o = ns.widgets.$dialog.domwindowdialog 'option'
      equal o.width, 300, '2nd setup - width'
      equal o.height, 400, '2nd setup - height'


    asyncTest 'domwindowdialog events passed via open', ->

      expect 8

      $.ui.domwindowdialog.setup
        ajaxdialog: true
      api = win.domwindowApi
      $dialog = ns.widgets.$dialog

      console.log win.domwindowApi

      api.open 'dialogfragment.html',
        beforeopen: (e, data) ->
          ok true, 'beforeopen'
          equal data.dialog[0], $dialog[0], 'beforeopen: dialog was passed'
        afteropen: (e, data) ->
          ok true, 'afteropen'
          equal data.dialog[0], $dialog[0], 'afteropen: dialog was passed'
          wait(0).done -> api.close()
        beforeclose: (e, data) ->
          ok true, 'beforeclose'
          equal data.dialog[0], $dialog[0], 'beforeclose: dialog was passed'
        afterclose: (e, data) ->
          ok true, 'afterclose'
          equal data.dialog[0], $dialog[0], 'afterclose: dialog was passed'
          start()


    asyncTest 'domwindowdialog events passed via jquery binding', ->

      expect 12

      $.ui.domwindowdialog.setup
        ajaxdialog: true
      api = win.domwindowApi
      $dialog = ns.widgets.$dialog

      $dialog.on 'domwindowdialog.beforeopen', (e, data) ->
        ok true, 'beforeopen'
        equal data.dialog[0], $dialog[0], 'beforeopen - data.dialog is dialogEl'
        equal @, $dialog[0], 'beforeopen - this is dialogEl'

      $dialog.on 'domwindowdialog.afteropen', (e, data) ->
        ok true, 'afteropen'
        equal data.dialog[0], $dialog[0], 'afteropen - data.dialog is dialogEl'
        equal @, $dialog[0], 'afteropen - this is dialogEl'
        wait(0).done -> api.close()

      $dialog.on 'domwindowdialog.beforeclose', (e, data) ->
        ok true, 'beforeclose'
        equal data.dialog[0], $dialog[0], 'beforeclose - data.dialog is dialogEl'
        equal @, $dialog[0], 'beforeclose - this is dialogEl'

      $dialog.on 'domwindowdialog.afterclose', (e, data) ->
        ok true, 'afterclose'
        equal data.dialog[0], $dialog[0], 'afterclose - data.dialog is dialogEl'
        equal @, $dialog[0], 'afterclose - this is dialogEl'
        start()

      api.open 'dialogfragment.html'


    asyncTest 'domwindowdialog events passed via setup', ->

      expect 4

      $.ui.domwindowdialog.setup
        ajaxdialog: true
        beforeopen: ->
          ok true, 'beforeopen'
        afteropen: ->
          ok true, 'afteropen'
          wait(0).done -> api.close()
        beforeclose: ->
          ok true, 'beforeclose'
        afterclose: ->
          ok true, 'afterclose'
          start()

      api = win.domwindowApi
      api.open 'dialogfragment.html',


    asyncTest 'domwindowdialog events passed via setup ensure events are fired everytime', ->

      expect 13

      $.ui.domwindowdialog.setup
        ajaxdialog: true
        beforeopen: ->
          ok true, 'beforeopen'
        afteropen: ->
          ok true, 'afteropen'
          wait(0).done -> api.close()
        beforeclose: ->
          ok true, 'beforeclose'
        afterclose: ->
          ok true, 'afterclose'

      api = win.domwindowApi
      api.open 'dialogfragment.html',
        afterclose: ->
          api.open 'dialogfragment.html',
            afterclose: ->
              api.open 'dialogfragment.html',
                afterclose: ->
                  ok true, 'everything worked'
                  start()


    asyncTest 'domwindowdialog events passed via close', ->

      expect 4

      $.ui.domwindowdialog.setup
        ajaxdialog: true
      api = win.domwindowApi

      api.open 'dialogfragment.html',
        beforeopen: ->
          ok true, 'beforeopen'
        afteropen: ->
          ok true, 'afteropen'
          wait(0).done ->
            api.close
              beforeclose: ->
                ok true, 'beforeclose'
              afterclose: ->
                ok true, 'afterclose'
                start()


    asyncTest 'domwindowdialog events ensure complicated events are all fired', ->

      expect 15

      $.ui.domwindowdialog.setup
        ajaxdialog: true
        beforeopen: -> ok true, 'beforeopen - via setup' # will be fired twice
        afteropen: -> ok true, 'afteropen - via setup' # will be fired twice
        beforeclose: -> ok true, 'beforeclose - via setup' # will be fired twice
        afterclose: -> ok true, 'afterclose - via setup' # will be fired twice

      api = win.domwindowApi

      firstOpen = ->

        api.open 'dialogfragment.html',
          beforeopen: -> ok true, 'beforeopen - via open' # will be fired once
          afteropen: ->
            ok true, 'afteropen - via open' # will be fired once
            wait(0).done ->
              api.close
                beforeclose: ->
                  ok true, 'beforeclose - via close' # will be fired once
                afterclose: ->
                  ok true, 'afterclose - via close' # will be fired once
                  secondOpen()
          beforeclose: -> ok true, 'beforeclose - via open' # will be fired once
          afterclose: -> ok true, 'afterclose - via open' # will be fired once

      secondOpen = ->

        api.open 'dialogfragment.html',
          afteropen: -> wait(0).done -> api.close()
          afterclose: ->
            ok true, 'afterclose - via open' # will be fired once
            start()

      firstOpen()

    asyncTest 'domwindowdialog ajaxdialog', ->

      expect 1

      $.ui.domwindowdialog.setup
        ajaxdialog: true
      api = win.domwindowApi

      api.open 'dialogfragment.html',
        afteropen: (e, data) ->
          equal (data.dialog.find '.woot').text(), 'woot', 'fetched html was in dialog'
          wait(0).done -> api.close()
        afterclose: ->
          start()

    
    asyncTest 'domwindowdialog iframedialog', ->

      expect 1

      $.ui.domwindowdialog.setup
        iframedialog: true
      api = win.domwindowApi

      api.open 'dialogfragment.html',
        afteropen: (e, data) ->
          ok (data.dialog.find 'iframe').size(), 'iframe was in dialog'
          wait(0).done -> api.close()
        afterclose: ->
          start()


    asyncTest 'domwindowdialog iddialog', ->

      expect 1

      $testdiv.html """
        <script type="text/x-dialogcontent" id="foobar"><i>foobar</i></script>
      """
      $.ui.domwindowdialog.setup
        iddialog: true
      api = win.domwindowApi

      api.open 'foobar',
        afteropen: (e, data) ->
          equal (data.dialog.find 'i').text(), 'foobar', 'fetched html was in dialog'
          wait(0).done ->
            api.close()
        afterclose: ->
          $testdiv.empty()
          start()


    asyncTest 'domwindowdialog iddialog via passing #id string', ->

      expect 1

      $testdiv.html """
        <script type="text/x-dialogcontent" id="foobar"><i>foobar</i></script>
      """
      $.ui.domwindowdialog.setup
        ajaxdialog: true
      api = win.domwindowApi

      api.open '#foobar',
        afteropen: (e, data) ->
          equal (data.dialog.find 'i').text(), 'foobar', 'fetched html was in dialog'
          wait(0).done -> api.close()
        afterclose: ->
          $testdiv.empty()
          start()


    asyncTest 'domwindowdialog deferredopen', ->

      expect 2

      $.ui.domwindowdialog.setup()
      api = win.domwindowApi

      api.open (defer) ->
        wait(0).done -> defer.resolve('<div class="moo">moo<div>')
      ,
        afteropen: (e, data) ->
          ok true, 'deferredopen worked'
          equal (data.dialog.find '.moo').text(), 'moo', 'attached html was in dialog'
          wait(0).done -> api.close()
        afterclose: ->
          start()


    asyncTest 'widgetstyle events', ->
      
      expect 18

      $dialog = $.ui.domwindowdialog.setup()
      $testdiv.html """
        <script type="text/x-dialogcontent" id="foobar"><i>foobar</i></script>
      """
      $domwin = $testdiv.find('#foobar').domwindow()
      domwin = $domwin.data 'uiDomwindow'

      firstClose = $.Deferred()
      secondClose = $.Deferred()

      $domwin.on 'domwindow.beforeopen', (e, data) ->
        ok true, 'beforeopen - fired'
        equal $dialog[0], data.dialog[0], 'beforeopen - dialog was passed'

      $domwin.on 'domwindow.afteropen', (e, data) ->
        ok true, 'afteropen - fired'
        equal $dialog[0], data.dialog[0], 'afteropen - dialog was passed'
        ok (data.dialog.find('i').size() is 1), 'afteropen - found attached html in dialog'
        wait(0).done -> domwin.close()

      $domwin.on 'domwindow.beforeclose', (e, data) ->
        ok true, 'beforeclose - fired'
        equal $dialog[0], data.dialog[0], 'beforeclose - dialog was passed'

      $domwin.on 'domwindow.afterclose', (e, data) ->
        ok true, 'afterclose - fired'
        equal $dialog[0], data.dialog[0], 'afterclose - dialog was passed'
        unless firstClose.state() is 'resolved'
          firstClose.resolve()
        else
          secondClose.resolve()

      firstClose.done -> domwin.open()
      secondClose.done -> start()
      domwin.open()


    asyncTest 'widgetstyle events ensure they work with api call', ->
      
      expect 18

      $dialog = $.ui.domwindowdialog.setup
        iddialog: true
      $testdiv.html """
        <script type="text/x-dialogcontent" id="foobar"><i>foobar</i></script>
      """
      api = win.domwindowApi
      $domwin = $testdiv.find('#foobar').domwindow()
      domwin = $domwin.data 'uiDomwindow'

      firstClose = $.Deferred()
      secondClose = $.Deferred()

      $domwin.on 'domwindow.beforeopen', (e, data) ->
        ok true, 'beforeopen - fired'
        equal $dialog[0], data.dialog[0], 'beforeopen - dialog was passed'

      $domwin.on 'domwindow.afteropen', (e, data) ->
        ok true, 'afteropen - fired'
        equal $dialog[0], data.dialog[0], 'afteropen - dialog was passed'
        ok (data.dialog.find('i').size() is 1), 'afteropen - found attached html in dialog'
        wait(0).done -> api.close()

      $domwin.on 'domwindow.beforeclose', (e, data) ->
        ok true, 'beforeclose - fired'
        equal $dialog[0], data.dialog[0], 'beforeclose - dialog was passed'

      $domwin.on 'domwindow.afterclose', (e, data) ->
        ok true, 'afterclose - fired'
        equal $dialog[0], data.dialog[0], 'afterclose - dialog was passed'
        unless firstClose.state() is 'resolved'
          firstClose.resolve()
        else
          secondClose.resolve()

      firstClose.done -> domwin.open()
      secondClose.done -> start()
      api.open 'foobar'


) jQuery, @
