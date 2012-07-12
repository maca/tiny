require 'tilt'
require 'haml'
require 'rack/utils'
require 'tiny/version'
require 'ext/tilt/template'

module Tiny
  module Helpers
    def self.included base
      if defined?(ActionView) && base == ActionView::Base 
        base.send :include, ActionViewHelpers
      else
        base.send :include, RubyHelpers
        base.send :include, ERBHelpers
        base.send :include, HamlHelpers
      end
    end

    module TextHelpers
      def html_tag name, attrs = {}, &block
        Tag.new(name, attrs).render(self, &block)
      end

      def text content
        output_buffer << Rack::Utils.escape_html(content.to_s) + "\n"
      end

      def text! content
        output_buffer << content.to_s + "\n"
      end
    end

    module ActionViewHelpers
      include TextHelpers

      def tiny_capture *args, &block
        capture(*args, &block)
      end

      def tiny_concat markup
        output_buffer << markup.html_safe and nil
      end
    end 

    module HamlHelpers
      def tiny_capture *args, &block
        Haml::Helpers.block_is_haml?(block) ? capture_haml(*args, &block) : super
      end

      def output_buffer
        defined?(haml_buffer) ? haml_buffer.buffer : super
      end
    end

    module ERBHelpers
      attr_reader :tilt_context

      def tiny_capture *args, &block
        return super unless tilt_context
        with_blank_buffer(*args, &block)
      end

      def with_blank_buffer *args, &block
        buffer = output_buffer.dup
        output_buffer.clear and yield(*args)
        return output_buffer.dup
      ensure
        output_buffer.replace buffer
      end

      def tiny_concat markup
        return super unless tilt_context
        output_buffer << markup and nil
      end

      def output_buffer
        return super unless tilt_context
        outvar = tilt_context.instance_variable_get(:@outvar)
        instance_variable_get outvar
      end
    end

    module RubyHelpers
      include TextHelpers
      alias :tag :html_tag

      def tiny_capture *args, &block
        __buffers << ''
        yield *args
        __buffers.pop
      end

      def tiny_concat markup
        if __buffers.size == 1
          markup
        else
          output_buffer << markup
        end
      end

      def __buffers
        @__buffers ||= ['']
      end

      def output_buffer
        __buffers.last
      end
    end
  end

  class Tag
    attr_reader :tag_name, :attrs

    def initialize tag_name, attrs = {}
      @tag_name, @attrs = tag_name, attrs
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
      scope.tiny_concat render_tag(content)
    end

    def render_tag content
      if content
        content.gsub!(/^(?!\s*$)/, "  ")
        content.gsub!(/\A(?!$)|(?<!^|\n)\z/, "\n") 
        %{<#{tag_name}#{tag_attributes}>#{content}</#{tag_name}>}
      else
        %{<#{tag_name}#{tag_attributes} />}
      end
    end
  end

  Sinatra.register self if defined?(Sinatra)
  ActionView::Base.send :include, Helpers if defined?(ActionView)
end
