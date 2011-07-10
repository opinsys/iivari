# ordered many-to-one association (many channels, one display)
class DisplaysChannel < ActiveRecord::Base
  belongs_to :display
  belongs_to :channel
  acts_as_list :scope => :display
end
