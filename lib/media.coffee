window.requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame
window.cancelAnimationFrame = window.cancelAnimationFrame || window.mozCancelAnimationFrame || window.webkitCancelAnimationFrame


class Manager
    constructor: ({ @visualizer, @stream, browser } = {}) ->

        @browser =
            loadAudioViaXMLHTTPRequestForSafari: true
            isSafari: (window.webkitAudioContext != undefined)

        for k, v of browser
            if {}.hasOwnProperty.call @browser, k then @browser[k] = v

    audioContext: new (window.AudioContext || window.webkitAudioContext)()

    createStream: (src) ->
        @stream = new Stream
            src:
                mpg: src.mpg
                ogg: src.ogg
            callback: () =>
                setTimeout(() =>

                    if @browser.isSafari and @browser.loadAudioViaXMLHTTPRequestForSafari
                        @stream.sourceJS.onaudioprocess = () =>
                            @visualizer.render()
                        @stream.source.start(0)

                    else
                        @stream.audio.play()
                        if @browser.isSafari == false then @visualizer.render()

                , 0)


class Stream
    constructor: ({ @src, @callback } = {}) ->
        @context = manager.audioContext
        @source = null
        @analyser = null
        @callback ||= @noop

        @analyser = @context.createAnalyser()
        @analyser.fftSize = 2048
        @analyser.smoothingTimeConstant = 0.3

        if manager.browser.isSafari and manager.browser.loadAudioViaXMLHTTPRequestForSafari == true
            console.log '?'

            request = new XMLHttpRequest()
            request.open('GET', @src.mpg, true)
            request.responseType = 'arraybuffer'

            @source = @context.createBufferSource()

            request.onload = () =>
                @context.decodeAudioData request.response, (buffer) =>

                    @sourceJS = @context.createScriptProcessor(2048)
                    @sourceJS.buffer = buffer
                    @sourceJS.connect(@context.destination)

                    @source.buffer = buffer
                    @source.connect(@analyser)
                    @source.connect(@context.destination)

                    @callback @

            request.send()

        else
            @audio = new Audio()
            @audio.src = if @audio.canPlayType('audio/ogg') == 'probably' then @src.ogg else @src.mpg

            @source = @context.createMediaElementSource(@audio)
            @source.connect(@analyser)
            @analyser.connect(@context.destination)

            @callback @



    noop: ->

    destroy: (callback) ->
        # @audio.pause()

        setTimeout(() ->
            console.log 'done'
            @audio     = null
            @context   = null
            @source    = null
            @callback  = null
            @analyser  = null
            callback()
        , 500)



class Visualizer
    constructor: () ->
        @canvas  = null
        @context = null
        @width   = null
        @height  = null


    register: ({ selector, renderer } = {}) ->
        @canvas  = document.querySelector(selector or 'canvas')
        @context = @canvas.getContext('2d')

        @width          = window.innerWidth
        @height         = window.innerHeight

        @context.width  = @width
        @context.height = @height

        @canvas.setAttribute 'width', @width
        @canvas.setAttribute 'height', @height

        window.addEventListener 'resize', @onResize, false
        window.addEventListener 'orientationchange', @onResize, false

        @renderer = renderer or @renderer.bind(@)

    onResize: () =>
        @width = window.innerWidth
        @height = window.innerHeight

        @canvas.setAttribute 'width', @width
        @canvas.setAttribute 'height', @height

    renderer: (bufferData, bufferLength) =>
        @context.clearRect(0, 0, @width, @height)

        @context.fillStyle = 'rgb(0, 0, 0)'
        @context.fillRect(0, 0, @width, @height)

        barWidth = (@width / bufferLength) * 2.5
        barHeight

        x = 0
        i = 0
        while i < bufferData.length
            u8Int = bufferData[i]

            barHeight = bufferData[i] * 10

            @context.fillStyle = 'rgb(' + (barHeight) + ', 50, 50)'
            @context.fillRect(x, @height - barHeight, barWidth, barHeight)

            x += barWidth + 1
            i++


    render: =>
        if !manager.stream or !manager.stream.analyser then return

        bufferLength = manager.stream.analyser.frequencyBinCount
        bufferData = new Uint8Array(bufferLength)
        manager.stream.analyser.getByteFrequencyData(bufferData)

        @renderer bufferData, bufferLength

        unless manager.browser.isSafari and manager.browser.loadAudioViaXMLHTTPRequestForSafari
            window.requestAnimationFrame @render


visualizer = new Visualizer()



renderers =
    utility:
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

    circlesWhite: (bufferData, bufferLength) ->
        @context.clearRect(0, 0, @width, @height)
        @context.fillStyle = 'rgb(0, 0, 0)'
        @context.fillRect(0, 0, @width, @height)

        i = 0
        while i < bufferData.length
            @context.beginPath()
            @context.arc(@width / 2, @height / 2, bufferData[i], 0, (Math.PI * 2), false)
            @context.strokeStyle = 'white'
            @context.lineWidth = 1
            @context.stroke()
            @context.closePath()
            i++



$ ->

    window.manager = new Manager
        visualizer: visualizer
        stream: {}

    manager.visualizer.register
        selector: 'canvas'
        renderer: renderers.circlesWhite

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
