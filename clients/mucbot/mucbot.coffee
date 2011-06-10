net = require('net')
xmpp = require('node-xmpp')
child_process = require('child_process')

class LEDWall
    constructor: (host, port) ->
        @sock = net.createConnection port, host
        @sock.on 'connect', -> console.log 'LEDWall connected'
        @sock.on 'error', (e) =>
            console.error('LEDWall connection died: ' + e.toString())
        @sock.on 'close', =>
            @constructor host, port

    setPriority: (prio) ->
        @sock.write "040" + prio + "\r\n"

class TextGen
    constructor: ->
        @queue = []

    addText: (s1, s2) ->
        @queue.push [s1, s2]
        @launchRenderer()

    launchRenderer: ->
        if @queue.length < 1 || @renderer
            return

        [s1, s2] = @queue.shift()
        console.log 'shifted ' + s1 + ' ' + s2
        @renderer = child_process.spawn '../haskell/text', [s1, s2]
        console.log "new renderer: " + @renderer
        @renderer.on 'exit', =>
            console.log 'renderer exited'
            delete @renderer
            @launchRenderer()
        @renderer.stderr.pipe process.stderr, { end: false }
        @outputHandler(@renderer.stdout) if @outputHandler


ledwall = new LEDWall('ledwall.hq.c3d2.de', 1338)
text = new TextGen()
text.outputHandler = (output) ->
    ledwall.setPriority 4
    output.pipe ledwall.sock, { end: false }
    output.on 'close', ->
        ledwall.setPriority 0

text.addText "Hello", "World"
text.addText "C3D2", "HQ"
text.addText "Mate ist lecker", "Das hier liest keiner"
