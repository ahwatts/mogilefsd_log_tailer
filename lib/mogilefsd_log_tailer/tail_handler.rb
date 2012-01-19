require 'eventmachine'

module MogilefsdLogTailer
  class TailHandler < EventMachine::Connection
    def initialize(hostname, file)
      @hostname = hostname
      @received_data = ''
      @file = file
    end

    def post_init
      @received_data = ''
      send_data("!watch\r\n")
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
    end

    def print_log_entry(line)
      msg = "#{Time.now.to_s}: #{@hostname}: #{line}"
      @file.puts(msg)
      @file.flush
    end
  end
end
