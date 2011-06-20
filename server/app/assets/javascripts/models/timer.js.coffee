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

class Iivari.Models.Timer
    constructor: (@timer_json) ->
        #console.log "#{JSON.stringify(@timer_json)}"
        @type = @timer_json.type

        # range start_datetime..end_datetime the period of days when timer is active
        @start_date = new Date(@timer_json.start_date)
        @end_date = new Date(@timer_json.end_date)
        
        unless @timer_json.start_at
            console.log "Warning: start time was not given"
            return

        # range raw_start_time..raw_end_time the hours each day the timer is active
        @start_time = @timer_json.start_at.split(":").map((val,i) -> val*[60,1][i]).reduce (t,s) -> t+s
        @end_time = 
            if @timer_json.end_at
                @timer_json.end_at.split(":").map((val,i) -> val*[60,1][i]).reduce (t,s) -> t+s
            else
                if @timer_json.type == 'refresh' 
                then @start_time + 10 
                else 0

        # set description for logging
        @description = "#{@timer_json.type} on "+
            "#{@start_date.getFullYear()}-#{@start_date.getMonth()+1}-#{@start_date.getDate()} - " +
            "#{@end_date.getFullYear()}-#{@end_date.getMonth()+1}-#{@end_date.getDate()}" +
            " at #{@timer_json.start_at}"
        if @timer_json.end_at
            @description += " - #{@timer_json.end_at}"


    isActive: (at) ->
        # FIXME: start_datetime or end_datetime may not be set, that's ok
        #console.log @start_date, at, @end_date
        active = false

        # calculate end_date with end_time
        end_date = new Date(@end_date.getTime() + @end_time*60000)
        
        if @start_date <= at <= end_date
            # at is somewhere in between start_datetime and end_datetime
            time_at = at.getHours()*60 + at.getMinutes()
            #console.log @start_time, time_at, @end_time

            if @start_time <= @end_time
                #console.log 'day shift'
                active = @start_time <= time_at <= @end_time
            else
                #console.log 'night shift'
                active = ! (@end_time < time_at < @start_time)

        if active
            #console.log "timer #{@description} is active"
            return true
        else
            #console.log "timer #{@description} is not active at #{at}"
            return false

