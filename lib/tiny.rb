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
    alias :tag :html_tag

    def text content
      output_buffer << Rack::Utils.escape_html(content.to_s) + "\n"
    end

    def text! content
      output_buffer << content.to_s + "\n"
    end

    def self.included base
      if defined?(ActionView) && base == ActionView::Base 
        base.send :include, ActionViewHelpers
      else
        base.send :include, RubyHelpers
        base.send :include, ERBHelpers
        base.send :include, HamlHelpers
      end
    end

    module ActionViewHelpers
      def tiny_capture *args, &block
        capture(*args, &block)
      end

      def tiny_concat markup, block = nil
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
        with_blank_buffer(*args, &block)
      end

      def with_blank_buffer *args, &block
        buffer = output_buffer.dup
        output_buffer.clear and yield(*args)
        return output_buffer.dup
      ensure
        output_buffer.replace buffer
      end

      def tiny_concat markup, block = nil
        return super unless tilt_context
        output_buffer << markup and nil
      end

      def output_buffer
        if outvar = tilt_context.instance_variable_get(:@outvar)
          instance_variable_get outvar
        else
          @output_buffer ||= ''
        end
      end
    end

    module RubyHelpers
      def tiny_concat markup, block = nil
        output_buffer << markup
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
      scope.tiny_concat render_tag(content), block
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
