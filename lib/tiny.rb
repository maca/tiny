require 'tilt'
require 'haml'
require 'rack/utils'
require 'tiny/version'
require 'ext/tilt/template'

module Tiny
  module TextHelpers
    def text content
      output_buffer << Rack::Utils.escape_html(content.to_s) + "\n"
    end

    def text! content
      output_buffer << content.to_s + "\n"
    end
  end

  module Helper
    include TextHelpers

    def capture_erb *args, &block
      buffer = output_buffer.dup
      output_buffer.clear and yield(*args)
      return output_buffer.dup
    ensure
      output_buffer.replace buffer
    end

    class << self
      def included base
        if base == ActionView::Base
          base.send :include, Rails
        else
          base.send :include, Generic
        end
      end
    end

    module Rails
      def html_tag name, attrs = {}, &block
          puts capture('hi') { 'lo' }
        output = Widget.new(name, attrs) do |widget|
          text! capture_erb(widget, &block) if block_given?
        end.render(self)
        concat output.html_safe
        return nil
      end

      def erb_buffer
        output_buffer
      end
    end

    module Generic
      def html_tag name, attrs = {}, &block
        case @__tilt_context
        when Tilt::ErubisTemplate, Tilt::ERBTemplate


          output_buffer << Widget.new(name, attrs) do |widget|
            text! capture_erb(widget, &block) if block_given?
          end.render(self)
          return nil



        when Tilt::HamlTemplate
          Widget.new(name, attrs) do |widget|
            text! capture_haml(widget, &block) if block_given?
          end.render(self)
        when nil
          Widget.new(name, attrs, &block).render(self)
        end
      end

      alias tag html_tag

      def output_buffer
        outvar = @__tilt_context.instance_variable_get(:@outvar)
        instance_variable_get outvar
      end
    end
  end


  class Widget
    include TextHelpers

    attr_reader :tag_name, :attrs, :output_buffer

    def initialize tag_name, attrs = {}, &block
      @tag_name, @attrs, @block = tag_name, attrs, block
      @output_buffer = ''
    end

    def tag_attributes
      tag_attrs = attrs.map do |name, val|
        next if val.nil? || val == []
        val == true ? name : %{#{name}="#{[*val].join(' ')}"}
      end.compact.join(' ')

      tag_attrs.empty?? '' : " #{tag_attrs}"
    end

    def render scope
      @scope  = scope
      content = render_content

      content.gsub!(/^(?!\s*$)/, "  ")
      content.gsub!(/\A(?!$)|(?<!^)\z/, "\n") 
      %{<#{tag_name}#{tag_attributes}>#{content}</#{tag_name}>}
    end

    def tag *args, &block
      output_buffer << Widget.new(*args, &block).render(@scope)
    end

    def respond_to? method
      super or @scope.respond_to? method
    end

    private
    def render_content
      instance_exec(self, &@block) if @block
      output_buffer.strip
    end

    def method_missing *args, &block
      @scope.send *args, &block
    end
  end

  def self.registered app
    app.helpers Helper
  end

  Sinatra.register self if defined?(Sinatra)
  ActionView::Base.send :include, Helper if defined?(Rails)
end
