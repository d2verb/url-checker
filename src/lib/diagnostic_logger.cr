require "log"

module DiagnosticLogger
  struct Formatter < Log::StaticFormatter
    def run
      string Time.utc.to_s("%Y-%m-%d %H:%M:%S")
      string " ["
      severity
      string "]"
      string "@"
      string Fiber.current.name
      string ": "
      message
    end
  end

  def self.setup(filename : String)
    backend = Log::IOBackend.new(File.new(filename, "w"), formatter: Formatter)
    Log.setup(:info, backend)
  end
end
