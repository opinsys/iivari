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

#= require_self
#= require_tree ./templates
#= require_tree ./models
#= require_tree ./views

window.Iivari =
    Models: {}
    Collections: {}
    Routers: {}
    Views: {}

    init: ->
        new Iivari.Routers.MainRouter()
        # pushstate removes the hash (#) and rewrites the url, 
        # and the current state can be read from the url
        Backbone.history.start({pushState: true, root: "/"})

class Iivari.Routers.MainRouter extends Backbone.Router
    routes:
        "conductor?:params": "conductor",

    conductor: ->
        new Iivari.Views.Conductor()

