require "tilt"
require 'yaml'
require "rack/utils"

require "tiny/version"
require "ext/tilt/template"

module Tiny
  include Haml::Helpers if const_defined? :Haml

  module CaptureHelpers
    private
    def capture &block
      case @__tilt_context
      when Tilt::ErubisTemplate, Tilt::ERBTemplate
        erb_capture &block
      when Tilt::HamlTemplate
        capture_haml &block
      else
        scope = Tag === self ? @scope : self 
        Tag.new(scope, &block).buffer
      end
    end

    def concat content
      case @__tilt_context
      when Tilt::ErubisTemplate, Tilt::ERBTemplate
        erb_buffer << content
      else
        content
      end
    end

    def erb_capture
      buffer = erb_buffer.dup
      erb_buffer.clear and yield
      return erb_buffer.dup
    ensure
      erb_buffer.replace(buffer)
    end

    def erb_buffer
      outvar = @__tilt_context.instance_variable_get(:@outvar)
      instance_variable_get outvar
    end
  end

  module Helpers
    def tag name, content_or_attrs = {}, attrs = nil, &block
      Tag.new(self, name, content_or_attrs, attrs, &block).render 
    end

    class << self
      def included base
        base.send :include, CaptureHelpers
      end
    end
  end

  class Tag
    include Helpers
    attr_reader :tag_name, :attrs

    def initialize scope, tag_name, content_or_attrs = {}, attrs = nil, &block
      @buffer, @scope, @tag_name, @block = '', scope, tag_name, block
      if attrs.nil? && Hash === content_or_attrs
        @attrs   = content_or_attrs 
      else
        @attrs   = attrs || {}
        @content = content_or_attrs
      end
    end

    def render
      tag_attrs = attrs.map do |name, val|
        next if val.nil? || val == []
        val == true ? name : %{#{name}="#{[*val].join(' ')}"}
      end.compact.join(' ')

      tag_attrs = " #{tag_attrs}" unless tag_attrs.empty?
      %{<#{tag_name}#{tag_attrs}>#{content}</#{tag_name}>}
    end

    private
    def content
      @block and instance_exec(self, &@block) or @content
    end

    def tag *args
      @buffer << super(*args)
    end

    def text content
      @buffer << Rack::Utils.escape_html(content.to_s)
    end

    def text! content
      @buffer << content.to_s
    end

    def method_missing *args, &block
      @scope.send *args, &block
    end
  end

  def self.registered app
    app.helpers Helpers
  end

  Sinatra.register self if const_defined? :Sinatra
end
