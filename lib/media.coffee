window.requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame
window.cancelAnimationFrame = window.cancelAnimationFrame || window.mozCancelAnimationFrame || window.webkitCancelAnimationFrame


class Manager
    constructor: ({ @visualizer, @stream } = {}) ->

    audioContext: new (window.AudioContext || window.webkitAudioContext)()

    createStream: (src) ->
        @stream = new Stream
            src:
                mpg: src.mpg
                ogg: src.ogg
            callback: () =>
                setTimeout(() =>
                    @stream.audio.play()
                    @visualizer.render()
                , 0)


class Stream
    constructor: ({ @src, @precision, @callback } = {}) ->
        @context = manager.audioContext
        @source = null
        @analyser = null
        @precision ||= 128
        @callback ||= @noop

        @audio = new Audio()
        @audio.src = if @audio.canPlayType('audio/ogg') == 'probably' then @src.ogg else @src.mpg

        @analyser = @context.createAnalyser()
        @analyser.fftSize = @precision

        @source = @context.createMediaElementSource(@audio)
        @source.connect(@analyser)

        @analyser.connect(@context.destination)

        @callback @


    noop: ->

    destroy: (callback) ->
        console.log 'destroy'
        @audio.pause()

        setTimeout(() ->
            console.log 'done'
            @audio     = null
            @context   = null
            @source    = null
            @precision = null
            @callback  = null
            @analyser  = null
            callback()
        , 500)



class Visualizer
    constructor: () ->
        @canvas       = null
        @context      = null
        @width        = null
        @height       = null

        @precision    = 128
        @resizeTimer  = null
        @deboundSpeed = 200


    register: ({ selector, width, height } = {}) ->
        @canvas  = document.querySelector(selector or 'canvas')
        @context = @canvas.getContext('2d')
        @width   = width or window.innerWidth
        @height  = height or window.innerHeight

        @context.width  = @width
        @context.height = @height

        window.addEventListener 'resize', @onResize, false

    onResize: () =>
        window.clearTimeout @resizeTimer
        @resizeTimer = setTimeout(() =>
            console.log 'resize'
        @deboundSpeed)

    u8RGB: (n) ->
        r = n >> 16 & 255
        g = n >> 8 & 255
        b = n & 255
        return { r: r, g: g, b: b }

    padBin: (n) ->
        str = n.toString(2)
        while str.length < 8
            str = '0' + str
        str

    render: =>
        if !manager.stream or !manager.stream.analyser then return

        frequencyByteData = new Uint8Array(manager.stream.analyser.frequencyBinCount)
        manager.stream.analyser.getByteFrequencyData(frequencyByteData)

        i = 0
        while i < frequencyByteData.length
            u8Int = frequencyByteData[i]
            u8Str = @padBin(u8Int)
            color = @u8RGB(u8Str)
            rgba = 'rgba(' + color.r + ', ' + color.g + ', ' + color.b + ', 0.5)'
            @context.beginPath()
            @context.arc(@width / 2, @height / 2, u8Int * 100 / 16, 0, (Math.PI * 2), false)

            @context.fillStyle = rgba
            @context.fill()

            i++

        window.requestAnimationFrame @render



window.manager = new Manager
    visualizer: new Visualizer()
    stream: {}

$ ->


    manager.visualizer.register()

    src =
        mpg: 'http://localhost:8000/demo/HM1.mp3'
        ogg: 'http://localhost:8000/demo/HM1.ogg'

    handleClick = () ->
        if !manager? then return
        if manager.stream and manager.stream instanceof Stream
            manager.stream.destroy () ->
                manager.createStream src
        else
            manager.createStream src

    $(document).on 'click touchend', handleClick
