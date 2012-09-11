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


# Polls the server for running docsplit tasks.
# If initialised with task count of 0, exits immediately.
# When a running task is finished, the current page
# will be reloaded.
# A small notification at the bottom of channel slides list
# is updated to present the user that the task is running.
class Iivari.Views.DocscplitTaskView

    taskComplete = null
    nextPoll = null

    constructor: (@school_id, @channel_id, @task_count) ->

    start: =>
        if @task_count == 0
            # nothing to do here
            return
        @taskComplete = new $.Deferred()
        @taskComplete.promise().done ->
            # reload the window when all tasks are ready
            setTimeout ->
                window.location.reload(true)
            , 2000

        # create status element
        @taskStatus = document.createElement "div"
        $("ul#slides").append @taskStatus
        # start polling the server
        @nextPoll = setInterval @poll, 3000

    poll: =>
        $.ajax
            type: "GET",
            dataType: "json",
            url: "doc_upload_progress",

            success: (data, textStatus, jqXHR) =>
                if data.status == "pending"
                    $(@taskStatus).text "job in progress, #{data.progress}%"
                    return
                # no pending operations, stop polling
                clearTimeout @nextPoll
                # if a task is resolved, reload view
                if data.status == "resolved"
                    $(@taskStatus).text "job finished!"
                    @taskComplete.resolve()

            error: (jqXHR, textStatus, errorThrown) =>
                console.log "error: #{jqXHR.responseText}"
                err = "#{textStatus} #{jqXHR.status}"
                alert err
                @taskComplete.reject()
