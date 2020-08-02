require "yaml"

struct Time::Span
  def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Time::Span
    unless node.is_a?(YAML::Nodes::Scalar)
      node.raise "Expected scalar, not #{node.class}"
    end

    node.value.to_f.seconds
  end
end

class Config
  include YAML::Serializable
  getter workers : Int32
  getter urls : Array(String)

  @[YAML::Field(converter: Time::Span)]
  getter period : Time::Span

  def self.load(config : String = File.read("config.yml"))
    Config.from_yaml(config)
  end
end
