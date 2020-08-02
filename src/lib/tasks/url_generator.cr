module UrlGenerator
  def self.run(config, url_stream)
    spawn do
      config.urls.each { |url|
        url_stream.send url
      }
    end
  end
end
