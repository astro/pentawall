player = 1

# ♥
display = (s) ->
    mEl = document.getElementById("m")
    mEl.innerHTML = s;


KEY_MAP =
    38: 1 # up
    40: 2 # down
    37: 4 # left
    39: 8 # right
    65: 64 # a
    83: 128 # s
    32: 16 # sp
    13: 32 # \n

input = 0

getPlayer = ->
    document.getElementById("player").blur()
    parseInt document.getElementById("player").value, 10

send = ->
    display "Not yet connected"
lastId = 1
requestTimes = {}

window.onkeydown = (ev) ->
    #console.log "key: #{ev.keyCode}"
    bit = KEY_MAP[ev.keyCode]
    if bit
        oldInput = input
        input = input | bit
        if input isnt oldInput
            send()

window.onkeyup = (ev) ->
    #console.log "key: #{ev.keyCode}"
    bit = KEY_MAP[ev.keyCode]
    if bit
        document.getElementsByTagName("body")[0].focus()
        oldInput = input
        input = input ^ bit
        if input isnt oldInput
            send()

socket = new io.Socket()
socket.connect()
socket.on 'connect', ->
    display "On-line!"

    send = ->
        requestTimes[lastId += 1] = new Date().getTime()
        socket.send JSON.stringify({ input, player: getPlayer(), id: lastId })
        display "Sent input=#{input}"

socket.on 'message', (m) ->
    try
        console.log m
        m = JSON.parse(m)
        if m.rtt
            display "#{m.rtt}"
        if m.id and requestTimes[m.id]
            rtt = new Date().getTime() - requestTimes[m.id]
            delete requestTimes[m.id]
            display "Websocket RTT: #{rtt} ms + Backend-Wall RTT: #{m.rtt} ms"
    catch e
        console.error e.stack or e
