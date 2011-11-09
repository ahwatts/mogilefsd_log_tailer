require 'mogilefsd_log_tailer/version'
require 'optparse'
require 'eventmachine'

class MogilefsdLogTailer
  module Handler
    def post_init
      @received_data = ''
    end

    def receive_data(data)
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      puts("Received #{data.inspect} from #{ip}:#{port}")
      if data =~ /\n/
        lines = data.split("\n")
        @received_data << lines.first
        print_log_entry(@received_data, ip, port)
        lines[1..-2].each { |l| print_log_entry(l, ip, port) }
        @received_data = lines.last
      else
        @received_data << data
      end
      puts("@received_data = #{@received_data}")
    end

    def print_log_entry(line, ip, port)
      puts("Printing line: #{line.inspect} from #{ip}:#{port}")
    end
  end

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

    while (h = ARGV.shift)
      @hosts << h
    end

    if @hosts.empty?
      STDERR.puts("No hosts to tail.")
      exit(1)
    end
  end

  def run
    EventMachine.run do
      @hosts.each do |hp|
        host, port = hp.split(':')
        EventMachine.connect(host, port.to_i, Handler)
      end
    end
  end
end
