require 'mogilefsd_log_tailer/version'
require 'optparse'

class MogilefsdLogTailer
  def initialize
    @hosts = []
  end

  def parse_options!
    OptionParser.new do |o|
      script_name = File.basename($0)
      o.set_summary_indent('  ')
      o.banner = "#{script_name} version #{VERSION}\nUsage: #{script_name} [options] tracker1:port1 tracker2:port2 ..."
      o.separator ""
      o.on_tail("-h", "--help", "Show this help message.") { puts o; exit }
    end.parse!
  end

  def run
    p @hosts
  end
end
