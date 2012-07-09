require 'tilt'
require 'haml'
require 'rack/utils'
require 'tiny/version'
require 'ext/tilt/template'

module Tiny
  module Helpers
    def html_tag name, attrs = {}, &block
      Tag.new(name, attrs).render(self, &block)
    end

    def text content
      output_buffer << Rack::Utils.escape_html(content.to_s) + "\n"
    end

    def text! content
      output_buffer << content.to_s + "\n"
    end

    def self.included base
      if defined?(ActionView) && base == ActionView::Base 
        base.send :include, Rails
      else
        base.send :include, Generic
      end
    end

    module Rails
      def tiny_capture *args, &block
        capture *args, &block
      end

      def erb_template?
        true
      end

      def haml_template?
      end
    end

    module Generic
      attr_reader :tilt_context

      def tag name, attrs = {}, &block
        html_tag name, attrs, &block
      end

      def block_is_haml? block
        eval 'defined? _hamlout', block.binding
      end
      
      def block_is_ruby? block
      end

      def tiny_capture *args, &block
        if block_is_haml? block
          capture_haml *args, &block
        else
          with_blank_buffer *args, &block
        end
      end

      def with_blank_buffer *args, &block
        buffer = output_buffer.dup
        output_buffer.clear and yield(*args)
        return output_buffer.dup
      ensure
        output_buffer.replace buffer
      end

      def erb_template?
        tilt_context.is_a?(Tilt::ERBTemplate)
      end

      def haml_template?
        tilt_context.is_a?(Tilt::HamlTemplate)
      end

      def output_buffer
        if outvar = tilt_context.instance_variable_get(:@outvar)
          instance_variable_get outvar
        else
          @output_buffer ||= ''
        end
      end
    end
  end

  class Tag
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
      content = scope.tiny_capture(self, &block) if block_given?

      if content
        content.gsub!(/^(?!\s*$)/, "  ") unless scope.erb_template?
        content.gsub!(/\A(?!$)|(?<!^|\n)\z/, "\n") 
        tag = %{<#{tag_name}#{tag_attributes}>#{content}</#{tag_name}>}
      else
        tag = %{<#{tag_name}#{tag_attributes} />}
      end

      tag = tag.html_safe if tag.respond_to?(:html_safe)
      return tag if scope.haml_template?
      scope.output_buffer << tag
      scope.output_buffer unless scope.erb_template?
    end
  end

  def self.registered app
    app.helpers Helpers
  end

  Sinatra.register self if defined?(Sinatra)
  ActionView::Base.send :include, Helpers if defined?(ActionView)
end
