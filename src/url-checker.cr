require "./lib/tasks/printer"
require "./lib/tasks/stats_writer"
require "./lib/tasks/status_checker"
require "./lib/tasks/avg_response_time"
require "./lib/concurrency_util"
require "./lib/config"
require "./lib/diagnostic_logger"
require "./lib/server/stats_store"

include ConcurrencyUtil

DiagnosticLogger.setup("log.txt")

config = Config.load
interrupt_url_generation = Channel(Nil).new
interrupt_ui = Channel(Nil).new

Signal::INT.trap do
  Fiber.current.name = "signal_handler"
  Log.info { "shutting down" }
  interrupt_url_generation.send nil
  interrupt_ui.send nil
end

url_stream = every(config.period, interrupt: interrupt_url_generation) {
  Log.info { "sending urls" }
  config.urls
}

status_stream = StatusChecker.run(url_stream, workers: config.workers)
success_stream, failure_stream = status_stream.partition { |v|
  v.is_a?(StatusChecker::Success) && v.status_code < 400
}

enriched_success_stream = AvgResponseTime.run(success_stream, width: 5)

stats_store = StatsStore.new

writer_done = StatsWriter.run(enriched_success_stream | failure_stream, stats_store)

stats_stream = every(1.seconds, name: "stats_watcher", interrupt: interrupt_ui) {
  Log.info { "reading from stats store" }
  [stats_store.get]
}

printer_done = Printer.run(stats_stream)

printer_done.receive?
writer_done.receive?

Log.info { stats_store.get }
sleep 0.5

puts "\rgoodbye"
