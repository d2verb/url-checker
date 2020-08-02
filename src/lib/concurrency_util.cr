require "log"

module ConcurrencyUtil
  def timer(time : Time::Span)
    Channel(Nil).new(1).tap { |ch|
      spawn(name: "timer") do
        sleep time
        ch.send(nil)
      end
    }
  end

  def every(period : Time::Span,
            interrupt : Channel(Nil) = Channel(Nil).new,
            name : String = "generator",
            &block : -> Enumerable(T)) forall T
    Channel(T).new.tap { |out_stream|
      spawn(name: "generator") do
        loop do
          select
          when timer(period).receive
            block.call.each { |value|
              out_stream.send value
            }
          when interrupt.receive
            break
          end
        end
      ensure
        out_stream.close
      end
    }
  end
end

abstract class Channel(T)
  def partition(&predicate : T -> Bool) : {Channel(T), Channel(T)}
    {Channel(T).new, Channel(T).new}.tap { |pass, fail|
      spawn do
        loop do
          value = self.receive
          predicate.call(value) ? pass.send(value) : fail.send(value)
        end
      rescue Channel::ClosedError
        pass.close; fail.close
      end
    }
  end

  def |(other : Channel(K)) : Channel(T | K) forall K
    Channel(K | T).new.tap { |output_stream|
      spawn do
        loop do
          output_stream.send Channel.receive_first(self, other)
        end
      rescue Channel::ClosedError
        output_stream.close
      end
    }
  end
end
