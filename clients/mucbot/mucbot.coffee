JID = 'collector@jabber.ccc.de'
PASSWORD = 'traversal'
MUC_JID = 'c3d2@muc.hq.c3d2.de/Pentawall'

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

    rmUTF8: (s) ->
        for i in [0..s.length]
            if s.charCodeAt(i) > 0x7F
                console.log 'rmUTF8 ' + i + ' ' + s + ' -> ' + s.substr(0, i) + '?' + s.substr(i + 1)
                s = s.substr(0, i) + '?' + s.substr(i + 1)
        s

    addText: (s1, s2) ->
        @queue.push [@rmUTF8(s1), @rmUTF8(s2)]
        @launchRenderer()

    launchRenderer: ->
        if @queue.length < 1 || @renderer?
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

##
# Glue textgen to ledwall server
ledwall = new LEDWall('ledwall.hq.c3d2.de', 1338)
text = new TextGen()
text.outputHandler = (output) ->
    ledwall.setPriority 4
    output.pipe ledwall.sock, { end: false }
    output.on 'close', ->
        ledwall.setPriority 1

##
# Going online
room = (new xmpp.JID(MUC_JID)).bare().toString()
cl = new xmpp.Client({ jid: JID, password: PASSWORD })
cl.on 'online', ->
    text.addText JID + " online", "Joining " + room
    cl.send new xmpp.Element('presence', { to: MUC_JID }).
            c('x', { xmlns: 'http://jabber.org/protocol/muc' })

##
# Handle incoming room messages
cl.on 'stanza', (stanza) ->
    #console.log stanza.toString()
    from = new xmpp.JID(stanza.attrs.from)
    if stanza.name is 'message' &&
       stanza.attrs.type is 'groupchat' &&
       from.bare().toString() is room

        title = `from.resource ?
                "<" + from.resource + ">" :
                "***"`
        body = stanza.getChildText('body')
        if body?
            text.addText title, body
