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

    window.slideNumber = 0    # slideshow v1, native javascript
    window.slideData = new Object()

    # NOTE: requires global window objects with the original native slideshow:
    #  * window.json_url (string)
    #  * window.cache (boolean)
    #  * window.preview (boolean)
    #  * window.data_update_interval (integer is ms)
    initialize: ->
        super()
        jqs5_init()
        updateSlideData(json_url, cache)
        showNextSlide(!preview)
        unless preview
            setInterval((() -> updateSlideData(json_url, cache)), data_update_interval)

