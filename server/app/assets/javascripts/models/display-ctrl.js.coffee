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


###
    DisplayCtrl handles the iivari client control signals.
    
    The client periodically sends a request for new control data from the server.
    The in-memory control data is checked in another timeout, and reacted upon on active timers.

###
class Iivari.Models.DisplayCtrl

    # Setup control data load and timer execution cycle.
    #
    # -- different intervals are useful, since update interval
    #    is probably best kept in several minutes, if not hours,
    #    and execute interval should be ~minute
    #
    constructor: (@json_url, @update_interval) ->
        console.log "DisplayCtrl UA: #{window.navigator.userAgent}"

        @ctrlData = new Object()
        @getCtrlData() # load control data from server

        # times [msec]
        @network_check_interval = 30000
        @execute_interval = 60000

        if @network_check_interval
            # network online/offline check
            setInterval @checkConnectivity, @network_check_interval
            console.log "/ping interval: #{@network_check_interval/1000} sec"
        if @update_interval
            # load new json data
            setInterval @getCtrlData, @update_interval
            console.log "#{@json_url} interval: #{@update_interval/1000} sec"
        if @execute_interval
            # execute timers
            setInterval @executeCtrlData, @execute_interval
            console.log "timer evaluation interval: #{@execute_interval/1000} sec"


    # check network online/offline status by requesting
    # HTTP HEAD from the server
    checkConnectivity: () =>
        $.ajax
            type: "HEAD",
            url: "/ping",
            cache: false,
            timeout: 3000,
            success: (data, textStatus, jqXHR) -> Iivari.onLine = true

            error: (jqXHR, textStatus, errorThrown) ->
                # response status other than 0 indicate that the server is responding
                # NOTE: server error 500 appears as 0
                try
                    console.log jqXHR.status
                catch e
                    # possibly INVALID_STATE_ERR: Dom Exception 11:
                    # An attempt to use an object no longer available,
                    # happens when network is disconnected.
                    Iivari.onLine = false
                    return

                if jqXHR.status == 0
                    console.log "Warning: server unreachable: #{textStatus}"
                    Iivari.onLine = false
                else
                    console.log "Warning: server ping: #{jqXHR.status}: #{jqXHR.statusText}"


    getCtrlData: () =>
        # console.log "load ctrl data from #{@json_url}"
        $.retrieveJSON @json_url, (json, status, attributes) =>
            if status == "success"
                console.log "Info: received new control data:\n#{JSON.stringify(json)}"
            if status == "cached"
                console.log("control data cached at "+attributes.cachedAt);
            if status != "notmodified"
                @ctrlData.json = json


    executeCtrlData: () =>
        unless window.display
            console.log "Warning: cannot execute display timers - no backend; will retry in #{parseInt @execute_interval/1000} seconds"
            return

        unless @ctrlData.json
            console.log "Warning: cannot execute display timers - no ctrl data retrieved from server or cache; will retry in #{parseInt @execute_interval/1000} seconds"
            return

        # FIXME: does new Date().getDay() always begin the week from Sunday,
        #        does it depend on client settings?
        # the data in timers json starts on Monday.
        # so, switch Sunday index 0 to 6 (and decrease other indices) by modulo
        now = new Date()
        day_of_week = (now.getDay()+6) % 7

        timers_today = @ctrlData.json.timers[day_of_week]
        #console.log "Info: timers: #{JSON.stringify(timers_today)}"
        
        # display power is on by default.
        # unless any poweroff timers are currently set,
        # disable possible expired poweroff timers by calling the powerOn() signal.
        power = true
        # active poweroff timers can be overridden by an active poweron timer
        powerOn_override = false

        # iterate over todays timers and create an object to test current activity
        for i,timer_json of timers_today
            timer = new Iivari.Models.Timer(timer_json)
            #console.log timer.description

            if timer.isActive(now)
                console.log "Info: #{timer.description} is active!"

                if timer.type == "poweroff"
                    power = false

                else if timer.type == "poweron"
                    powerOn_override = true

                else if timer.type == "refresh"
                    # signal to Python backend to refresh the webview
                    # NOTE: this will kill the client process (intentionally)!!!
                    window.display.refresh()

        # signal to Python backend to control display power
        if power or powerOn_override
            window.display.powerOn()
        else
            window.display.powerOff()


    $(window.applicationCache).bind 'checking', (event) ->
        console.log 'Info: checking manifest'

    $(window.applicationCache).bind 'downloading', (event) ->
        console.log 'downloading file into cache'

    #$(window.applicationCache).bind 'progress', (event) ->
    #  console.log 'file downloaded'

    $(window.applicationCache).bind 'noupdate', (event) ->
        console.log 'no updates to manifest'

    $(window.applicationCache).bind 'cached', (event) ->
        console.log 'Info: offline caching complete'

    $(window.applicationCache).bind 'updateready', (event) ->
        console.log 'Info: caching complete'
        # swapCache MAY trigger an error with PySide:
        # INVALID_STATE_ERR: DOM Exception 11: An attempt was made to use an object that is not, or is no longer, usable.
        window.applicationCache.swapCache()
        console.log 'swapped to new cache - restarting client process'
        window.display.forceRefresh() # ignores 10 minute bailout

    $(window.applicationCache).bind 'error', (event) ->
        console.log 'Warning: an error occurred while caching'

    $(window.applicationCache).bind 'obsolete', (event) ->
        console.log 'Warning: manifest cannot be found'
