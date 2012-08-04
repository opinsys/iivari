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

jQuery ->

    $('#sortable').sortable {
        revert: true
    }

    $('.draggable').draggable {
        connectToSortable: '#sortable',
        helper: 'original',
        revert: 'invalid'
    }

    $( "ul, li" ).disableSelection()

    # remove the new channel selector for non-JS browsers
    # and show the dynamic JS channel add button
    $('#new-channel').prev('li').remove()
    $('#new-channel').show()
    $('#new-channel').click -> newChannelItem()


newChannelItem = () ->
    console.log 'xxxx'
    sortable = $('#sortable')
    new_select = $(sortable.find('li')[0]).clone()
    # remove old channel selection
    new_select.find('option:selected').attr 'selected', null
    sortable.append new_select


