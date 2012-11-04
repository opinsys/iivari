#
# Define local Organisation instead of using Puavo API
#
puts "Starting up in STANDALONE mode without Puavo integration"

class LocalOrganisation
  attr_accessor :organisation_key, :host
  alias :key :organisation_key

  attr_writer :control_timers

  def name
    'Local organisation'
  end

  def value_by_key key
    case key
    when 'control_timers'
      @control_timers
    else nil
    end
  end
end
@organisation = LocalOrganisation.new
@organisation.organisation_key = 'default'
@organisation.host = '*'
Organisation.current= @organisation

