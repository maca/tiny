require 'tilt'
require 'haml'
require 'rack/utils'
require 'tiny/version'
require 'ext/tilt/template'

module Tiny
  module Helper
    def text content
      output_buffer << Rack::Utils.escape_html(content.to_s) + "\n"
    end

    def text! content
      output_buffer << content.to_s + "\n"
    end

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
        Widget.new(name, attrs).render(self, &block)
      end

      alias tag html_tag

      def output_buffer
        if outvar = @__tilt_context.instance_variable_get(:@outvar)
          instance_variable_get outvar
        else
          @output_buffer ||= ''
        end
      end
    end
  end

  class Widget
    attr_reader :tag_name, :attrs

    def initialize tag_name, attrs = {}, &block
      @tag_name, @attrs, @block = tag_name, attrs, block
    end

    def tag_attributes
      tag_attrs = attrs.map do |name, val|
        next if val.nil? || val == []
        val == true ? name : %{#{name}="#{[*val].join(' ')}"}
      end.compact.join(' ')

      tag_attrs.empty?? '' : " #{tag_attrs}"
    end

    def render scope, &block
      scope   = scope
      content = scope.capture_erb(&block) if block_given?
      
      if content
        content.gsub!(/^(?!\s*$)/, "  ")
        content.gsub!(/\A(?!$)|(?<!^)\z/, "\n") 
        tag = %{<#{tag_name}#{tag_attributes}>#{content}</#{tag_name}>}
      else
        tag = %{<#{tag_name}#{tag_attributes} />}
      end

      scope.output_buffer << tag
    end
  end

  def self.registered app
    app.helpers Helper
  end

  Sinatra.register self if defined?(Sinatra)
  ActionView::Base.send :include, Helper if defined?(Rails)
end
