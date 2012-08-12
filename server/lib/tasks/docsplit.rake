# encoding: utf-8
require "logger"
require "docsplit"
require 'declarative_authorization/maintenance'

$logger = Logger.new(File.join(Rails.root, 'log', 'docsplit.log'))
$logger.formatter = Logger::Formatter.new
$logger.level = Logger::INFO

Struct.new("Organisation", :key, :host)

namespace :iivari do

  task :docsplit => :environment do
    organisation = Struct::Organisation.new("default", "*")
    Organisation.current= organisation
    DocsplitTask.logger = $logger
    include Authorization::Maintenance

    DocsplitTask.find_pending.each do |task|
      begin
        # skip declarative_authorization for Slide creation
        t0 = Time.now
        without_access_control do
          task.process
        end
        $logger.info "Task #{task.id} finished in %.1f sec" % (Time.now - t0)
        task.resolved = true

      rescue
        $logger.error $!
        task.error = $!.message
        $logger.warn "Task #{task.id} failed, reason: #{task.error}"
        task.rejected = true

      ensure
        task.pending = false
        task.save
      end
    end
  end

end
