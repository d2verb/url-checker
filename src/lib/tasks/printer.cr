require "tablo"
require "crt"
require "log"

module Printer
  def self.run(stats_stream)
    Channel(Nil).new.tap { |done|
      spawn(name: "printer") do
        win = Crt::Window.new(48, 120)
        loop do
          data = stats_stream.receive.map { |v|
            [v[:url], v[:success], v[:failure], v[:avg_response_time].total_milliseconds]
          }
          table = Tablo::Table.new(data) do |t|
            t.add_column("Url", width: 24) { |n| n[0] }
            t.add_column("Success") { |n| n[1] }
            t.add_column("Failure") { |n| n[2] }
            t.add_column("Avg RT(ms)") { |n| n[3] }
          end
          win.clear
          win.print(0, 0, table.to_s)
          win.refresh
        end
      rescue Channel::ClosedError
        Log.info { "input stream was closed" }
      ensure
        Crt.done
        done.close
      end
    }
  end
end
