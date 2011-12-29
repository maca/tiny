require "tilt"
require "rack/utils"

require "tiny/version"
require "tiny/tilt"

module Tiny
  include Haml::Helpers if const_defined? :Haml

  class Context
    include MarkupHelpers
    attr_reader :buffer

    def initialize scope, &block
      @buffer, @scope = '', scope
      instance_eval &block
    end

    def tag *args
      @buffer << super(*args)
    end

    def text content
      @buffer << Rack::Utils.escape_html(content)
    end

    def text! content
      @buffer << content
    end

    def method_missing *args
      @scope.send *args
    end
  end

  def tag tag_name, content_or_attrs = {}, attrs = nil, &block
    if attrs.nil? && Hash === content_or_attrs
      attrs   = content_or_attrs 
      content = nil
    else
      attrs ||= {}
      content = content_or_attrs
    end

    attrs = attrs.map do |name, val|
      next if val.nil? || val == []
      val == true ? name : %{#{name}="#{[*val].join(' ')}"}
    end.compact.join(' ')

    attrs   = " #{attrs}" unless attrs.empty?
    content = capture(&block) if block_given?
    output  = %{<#{tag_name}#{attrs}>#{content}</#{tag_name}>}
    block_given? ? concat(output) : output
  end

  private
  def capture &block
    case @__tilt_context
    when Tilt::ErubisTemplate, Tilt::ERBTemplate
      erb_capture &block
    when Tilt::HamlTemplate
      capture_haml &block
    else
      scope = Context === self ? @scope : self 
      Context.new(scope, &block).buffer
    end
  end

  def concat content
    case @__tilt_context
    when Tilt::ErubisTemplate, Tilt::ERBTemplate
      erb_buffer << content
    when Tilt::HamlTemplate
      haml_concat content
    else
      content
    end
  end
 
  def erb_capture
    old_buffer = erb_buffer.dup
    erb_buffer.clear and yield
    content = erb_buffer.dup
    erb_buffer.replace(old_buffer) and content
  end

  def erb_buffer
    outvar = @__tilt_context.instance_variable_get(:@outvar)
    outvar or raise('Please pass the outvar option when instantiating the erb template')
    instance_variable_get outvar
  end
end
