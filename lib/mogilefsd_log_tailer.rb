require 'mogilefsd_log_tailer/version'
require 'mogilefsd_log_tailer/tail_handler'
require 'optparse'

module MogilefsdLogTailer
  def self.parse_options!
    hosts = []

    OptionParser.new do |o|
      script_name = File.basename($0)
      o.set_summary_indent('  ')
      o.banner = "#{script_name} version #{VERSION}\nUsage: #{script_name} [options] tracker1:port1 tracker2:port2 ..."
      o.separator ""
      o.on_tail("-h", "--help", "Show this help message.") { puts o; exit }
    end.parse!

    while (h = ARGV.shift)
      hosts << h
    end

    if hosts.empty?
      STDERR.puts("No hosts to tail.")
      exit(1)
    end

    [ hosts, {} ]
  end

  def self.run
    hosts, options = parse_options!

    EventMachine.run do
      hosts.each do |hp|
        host, port = hp.split(':')
        EventMachine.connect(host, port.to_i, TailHandler, host)
      end
    end
  end
end
