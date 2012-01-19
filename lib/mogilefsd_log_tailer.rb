require 'daemons'
require 'mogilefsd_log_tailer/version'
require 'mogilefsd_log_tailer/tail_handler'
require 'optparse'

module MogilefsdLogTailer
  def self.parse_options!
    hosts = []
    filename = nil
    daemonize = false

    OptionParser.new do |o|
      script_name = File.basename($0)
      o.set_summary_indent('  ')
      o.banner = "#{script_name} version #{VERSION}\nUsage: #{script_name} [options] tracker1:port1 tracker2:port2 ..."
      o.separator ""
      o.on("-d", "--[no-]daemonize", "Run as a daemon.") { |d| daemonize = d }
      o.on("-f", "--file FILE", "The log file to which the output should go.") { |n| filename = File.expand_path(n) }
      o.on("-h", "--help", "Show this help message.") { puts o; exit }
    end.parse!

    while (h = ARGV.shift)
      hosts << h
    end

    if hosts.empty?
      STDERR.puts("No hosts to tail.")
      exit(1)
    end

    [
      hosts,
      {
        :daemonize => daemonize,
        :filename => filename,
      },
    ]
  end

  def self.run
    hosts, options = parse_options!

    log_file = $stdout
    log_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

    if options[:filename]
      log_dir = File.dirname(options[:filename])
    end

    if options[:daemonize]
      Daemons.daemonize({
          :dir_mode => :normal,
          :dir => log_dir,
          :log_output => true,
        })
    end

    if options[:filename]
      log_file = File.open(options[:filename], 'ab')
    end

    EventMachine.run do
      hosts.each do |hp|
        host, port = hp.split(':')
        EventMachine.connect(host, port.to_i, TailHandler, host, log_file)
      end
    end
  end
end
