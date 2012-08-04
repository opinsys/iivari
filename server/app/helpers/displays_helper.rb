module DisplaysHelper

  # Outputs drop-down selector html of display channels.
  # Unless a display parameter is given, returns
  # selector for new channel.
  def channel_select display=nil
    draggable = '<li class="draggable"> <div class="dropdown">
        %s
    </div> </li>'
    if display and display.channels.any?
      # show selected display channels
      elements = display.channels.collect do |channel|
        draggable % select_tag(
          "channels[]", options_for_select(
            @channels, channel.id))
      end
      elements.to_s
    else
      # new channel selector
      draggable % select_tag(
        "channels[]", options_for_select(@channels, 0))
    end
  end

end
