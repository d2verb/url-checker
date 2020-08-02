require "http/client"
require "log"

module StatusChecker
  record Success, url : String, status_code : Int32, response_time : Time::Span
  record Failure, url : String, err : Exception

  private def self.get_status(url : String)
    start_time = Time.utc
    res = HTTP::Client.get url
    res.status_code
    Success.new(url, res.status_code, Time.utc - start_time)
  rescue e : Exception | Socket::Addrinfo::Error
    Failure.new(url, e)
  end

  def self.run(url_stream, workers : Int32)
    Channel(Success | Failure).new.tap { |url_status_stream|
      countdown = Channel(Nil).new(workers)
      spawn(name: "supervisor") do
        workers.times {
          countdown.receive
        }
        url_status_stream.close
      end

      workers.times { |w_i|
        spawn(name: "worker_#{w_i}") do
          loop do
            url = url_stream.receive
            result = get_status(url)
            url_status_stream.send result
          end
        rescue Channel::ClosedError
          Log.info { "input stream was closed" }
        ensure
          countdown.send nil
        end
      }
    }
  end
end
