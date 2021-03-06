require "../stats"
require "log"

module StatsWriter
  def self.run(url_status_stream, stats_store : StatsStore)
    Channel(Nil).new.tap { |done|
      spawn(name: "stats_writer") do
        loop do
          case received = url_status_stream.receive
          when {StatusChecker::Success, Time::Span}
            status_obj, avg_response_time = received.as({StatusChecker::Success, Time::Span})
            stats_store.log_success(status_obj.url, avg_response_time)
          when StatusChecker::Failure, StatusChecker::Success
            stats_store.log_failure(received.url)
          end
        end
      rescue Channel::ClosedError
        Log.info { "input stream was closed" }
      ensure
        done.close
      end
    }
  end
end
