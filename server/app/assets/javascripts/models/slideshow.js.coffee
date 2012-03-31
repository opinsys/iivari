###
Copyright © 2012 Opinsys Oy

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
###

class Iivari.Models.Slideshow

    SCREEN_WIDTH = window.innerWidth
    SCREEN_HEIGHT = window.innerHeight


    constructor: (@json_url, @data_update_interval, @preview, @cache) ->
        @slideData = null
        # hide slide container
        $(".slides-container").hide()


    start: ->
        # start superslides after receiving the first slide batch
        promise = @updateSlideData()
        promise.done =>
            @initSlideshow()
        promise.fail ->
            # FIXME: display error message on screen
        # start slide poll
        unless @preview
            setInterval @updateSlideData, @data_update_interval


    # render slides using Transparency.js
    renderSlides: =>
        if @preview
            console.log 'Preview mode'
            $("#slideshow").html(@slideData[0].slide_html)
        else
            $(".slides-container").render(
                @slideData,
                {slide: -> html: @slide_html})

        # resize fullscreen image -  maybe make scaling optional?
        footer = $(".footer_container").height()
        # $(".fullimg img").css {width: "#{SCREEN_WIDTH}px", height: "#{SCREEN_HEIGHT - footer}px"}
        # !!! no scaling
        # $(".fullimg img").css {width: "100%", height: "#{SCREEN_HEIGHT - footer}px"}


    initSlideshow: =>
        # FIXME: use @slideData[slideNumber].slide_delay value
        # FIXME: checkSlideTimerAndStatus

        if @preview
            $(".slides-container").show()
            return

        $('#slideshow').superslides
            delay: 10000
            play: true
            slide_speed: 2500
            slide_easing: "swing"
            container_class: "slides-container"

        $("#slideshow").trigger("slides.start")

        $("body").on "slides.initialized", "#slideshow", =>
            console.log 'Superslides initialized!'
            $(".slides-container").fadeIn(5000)


    updateSlideData: =>
        deferred = new $.Deferred()
        if @cache
            # jquery-offline handles transport errors
            # NOTE: if offline (no network), and even if server is localhost, json data is not requested!
            $.retrieveJSON @json_url, (json, status, attributes) =>
                unless json
                    console.log "No slide data received!"
                    deferred.reject()
                    return

                if not @slideData or status != "notmodified"
                    console.log "received #{json.length} slides"
                    @slideData = json
                    @renderSlides()
                    try
                        window.applicationCache.update()
                deferred.resolve()

        else
            $.ajax
                url: @json_url,
                dataType: 'json',
                cache: false,
                success: (data, textStatus, jqXHR) =>
                    console.log("received #{data.length} slides")
                    @slideData = data
                    @renderSlides()
                    deferred.resolve()

                error: (jqXHR, textStatus, errorThrown) ->
                    console.log "#{textStatus}: #{errorThrown}"
                    deferred.reject()

        return deferred.promise()

