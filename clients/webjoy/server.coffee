sendKey = ->

##
# Socket
##

net = require('net')
pentawall = null
sendKey = ->

setupPentawall = ->
    if pentawall
        return

    pentawall = net.createConnection(1338, 'ledwall.hq.c3d2.de')

    pentawall.on 'connect', ->
        console.log "Connected to Pentawall"
        pentawall.write "0400\r\n"
        sendKey = (player, input) ->
            pad = (s) ->
                if s.length < 2
                    pad "0#{s}"
                else
                    s
            s = "0A#{pad player.toString(16)}#{pad input.toString(16)}01\r\n"
            pentawall.write s

    reconnect = (e) ->
        if e
            console.error e.stack or e
        if pentawall
            try
                pentawall.end()
            catch e
            pentawall = null
            setTimeout setupPentawall, Math.ceil(Math.random() * 10) + 1
    pentawall.on 'error', reconnect
    pentawall.on 'end', reconnect
    pentawall.on 'close', reconnect

setupPentawall()

##
# Web
##

connect = require('connect')
socketIOconnect = require("socket.io-connect").socketIOconnect

server = connect.createServer(
    connect.logger('dev'),
    # socketIOconnect "middleware" does the same as Method 1 but more idiomatically
    # Always have socketIO middleware come first, so it can setup the socket.IO endpoint
    socketIOconnect( ->
        server
    , (client, req, res) ->
        client.send("Hello")
        client.on 'message', (m) ->
            try
                m = JSON.parse(m)
                console.log m
                sendKey m.player, m.input
            catch e
                console.error e.stack or e
    ),
    connect.static(__dirname + '/static')
)
server.listen(8000)  # Listen for requests
