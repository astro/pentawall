player = 1

# ♥
m = (s) ->
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
    m "Not yet connected"

window.onkeydown = (ev) ->
    #console.log "key: #{ev.keyCode}"
    bit = KEY_MAP[ev.keyCode]
    if bit
        input = input | bit
        send()

window.onkeyup = (ev) ->
    #console.log "key: #{ev.keyCode}"
    bit = KEY_MAP[ev.keyCode]
    if bit
        document.getElementsByTagName("body")[0].focus()
        input = input ^ bit
        send()

socket = new io.Socket(null, log: (s) -> m s)
socket.connect()
socket.on 'connect', ->
    m "On-line!"

    send = ->
        socket.send JSON.stringify({ input, player: getPlayer() })
        m "Sent input=#{input}"

