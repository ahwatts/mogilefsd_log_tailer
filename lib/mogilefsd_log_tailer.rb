require 'mogilefsd_log_tailer/version'
require 'optparse'
require 'eventmachine'
require 'socket'

class MogilefsdLogTailer
  module Handler
    def post_init
      @received_data = ''
      send_data("!watch\r\n")
    end

    def receive_data(data)
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      # puts("Received #{data.inspect} from #{ip}:#{port}")
      if data =~ /\r\n/
        lines = data.split("\r\n")
        lines.each_with_index do |line, i|
          # puts("line #{i}: #{line.inspect}")
          if i == 0
            print_log_entry(@received_data + line, ip, port)
            @received_data = ''
          elsif i == lines.size - 1
            @received_data << line
          else
            print_log_entry(line, ip, port)
          end
        end
      else
        @received_data << data
      end
      # puts("@received_data = #{@received_data.inspect}")
    end

    def print_log_entry(line, ip, port)
      puts("#{Time.now.to_s}: #{ip}:#{port}: #{line}")
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
