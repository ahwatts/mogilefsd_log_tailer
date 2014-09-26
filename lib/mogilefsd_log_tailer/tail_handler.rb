require 'eventmachine'
require 'socket'

module MogilefsdLogTailer
  class TailHandler < EventMachine::Connection
    def initialize(hostname, file)
      @hostname = hostname
      @received_data = ''
      @file = file
    end

    def post_init
      @received_data = ''
      pn = get_peername
      if pn.nil?
        @port, @ip = [ "unknown", -1 ]
      else
        @port, @ip = Socket.unpack_sockaddr_in(get_peername)
      end
    rescue
      $stderr.puts "Exception in post_init: %s (%p)\n\t%s" %
        [ $!.message, $!.class, $!.backtrace.join("\n\t") ]
    end

    def connection_completed
      send_data("!watch\r\n")
      @reconnects = 5
    rescue
      $stderr.puts "Exception in connection_completed: %s (%p)\n\t%s" %
        [ $!.message, $!.class, $!.backtrace.join("\n\t") ]
    end

    def receive_data(data)
      # puts(" - Received #{data.inspect} from #{@hostname}")
      if data =~ /\r\n/
        lines = data.split("\r\n", -1)
        lines.each_with_index do |line, i|
          if i == 0
            print_log_entry(@received_data + line)
            @received_data = ''
          elsif i == lines.size - 1
            @received_data << line
          else
            print_log_entry(line)
          end
        end
      else
        @received_data << data
      end
    rescue
      $stderr.puts "Exception in receive_data: %s (%p)\n\t%s" %
        [ $!.message, $!.class, $!.backtrace.join("\n\t") ]
    end

    def unbind
      if @reconnects > 0
        print_log_entry "[mogilefsd_log_tailer] Connection closed to #{@hostname} (#{@ip}:#{@port}), reconnects left: #{@reconnects}"
        @reconnects -= 1
        EventMachine::Timer.new(1) do
          print_log_entry "[mogilefsd_log_tailer] Reconnecting to #{@hostname} (#{@ip}:#{@port})..."
          reconnect(@ip, @port)
        end
      else
        print_log_entry "[mogilefsd_log_tailer] Giving up on #{@hostname} (#{@ip}:#{@port})"
        EventMachine::Timer.new(0.5) do
          if EventMachine.connection_count == 0
            EventMachine.stop_event_loop
          end
        end
      end
    rescue
      $stderr.puts "Exception in unbind: %s (%p)\n\t%s" %
        [ $!.message, $!.class, $!.backtrace.join("\n\t") ]
    end

    def print_log_entry(line)
      msg = "#{Time.now.to_s}: #{@hostname}: #{line}"
      @file.puts(msg)
      @file.flush
    end
  end
end
