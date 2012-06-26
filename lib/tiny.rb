require "tilt"
require 'yaml'
require "rack/utils"

require "tiny/version"
require "ext/tilt/template"

module Tiny
  module Helpers
    def tag name, attrs = {}, &block
      case @__tilt_context
      when Tilt::ErubisTemplate, Tilt::ERBTemplate
        erb_buffer << Widget.new(self, name, attrs) do |widget|
          text! capture_erb(widget, &block) if block_given?
        end.render 
      when Tilt::HamlTemplate
        Widget.new(self, name, attrs) do |widget|
          text! capture_haml(widget, &block) if block_given?
        end.render 
      when nil
        Widget.new(self, name, attrs, &block).render 
      end
    end

    def capture_erb *args
      buffer = erb_buffer.dup
      erb_buffer.clear and yield(*args)
      return erb_buffer.dup
    ensure
      erb_buffer.replace buffer
    end

    def erb_buffer
      outvar = @__tilt_context.instance_variable_get(:@outvar)
      instance_variable_get outvar
    end
  end

  class Widget
    attr_reader :tag_name, :attrs

    def initialize scope, tag_name, attrs = {}, &block
      @scope, @tag_name, @attrs, @block = scope, tag_name, attrs, block
      @buffer = ''
    end

    def tag_attributes
      tag_attrs = attrs.map do |name, val|
        next if val.nil? || val == []
        val == true ? name : %{#{name}="#{[*val].join(' ')}"}
      end.compact.join(' ')

      tag_attrs.empty?? '' : " #{tag_attrs}"
    end

    def render
      content = render_content
      # soft tabs
      content.gsub!(/^(?!\s*$)/, "  ")
      # Following line breaks 1.8.7 compatibility
      content.gsub!(/\A(?!\s*$)|(?<!^)\z/, "\r\n") 
      
      %{<#{tag_name}#{tag_attributes}>#{content}</#{tag_name}>}
    end

    def tag *args, &block
      @buffer << Widget.new(@scope, *args, &block).render 
    end

    def text content
      @buffer << Rack::Utils.escape_html(content.to_s) + "\r\n"
    end

    def text! content
      @buffer << content.to_s + "\r\n"
    end

    def respond_to? method
      super or @scope.respond_to? method
    end

    private
    def render_content
      instance_exec(self, &@block) if @block
      @buffer.strip
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