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

class Iivari.Views.Conductor extends Backbone.View
    el: "body"

    window.display = null     # backend proxy object for signaling
    Iivari.displayCtrl = null # display logic
    Iivari.onLine = true      # custom window.navigator.onLine replacement

    initialize: ->
        super()

    start: ->
        # Read variables from session object
        #  - slide data url
        json_url = Iivari.session.get "json_url"
        #  - slide data request interval (integer in ms)
        data_update_interval = Iivari.session.get "data_update_interval"
        #  - control data url
        ctrl_url = Iivari.session.get "ctrl_url"
        #  - control data request interval (integer in ms)
        ctrl_update_interval = Iivari.session.get "ctrl_update_interval"
        #  - use offline cache? (boolean)
        cache = Iivari.session.get "cache"
        #  - single slide preview mode? (boolean)
        preview = Iivari.session.get "preview"
        #  - footer timestamp locale
        locale = Iivari.session.get "locale"


        jqs5_init()
        Iivari.slideshow = new Iivari.Models.Slideshow(json_url, data_update_interval, preview, cache)
        Iivari.slideshow.start()

        unless preview
            # DisplayCtrl runs control timers and handles kiosk backend signaling.
            Iivari.displayCtrl = new Iivari.Models.DisplayCtrl(ctrl_url, ctrl_update_interval, locale)

