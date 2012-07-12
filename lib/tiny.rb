require 'tilt'
require 'haml'
require 'rack/utils'
require 'tiny/version'
require 'ext/tilt/template'

module Tiny
  module Helpers
    attr_reader :tilt_context

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
        base.send :include, Rails
      else
        base.send :include, Generic
      end
    end

    module Rails
      def tiny_capture *args, &block
        capture(*args, &block)
      end

      def tiny_concat markup, block = nil
        output_buffer << markup.html_safe and nil
      end
    end 

    module Generic
      def tiny_capture *args, &block
        if haml_block?(block)
          capture_haml(*args, &block)
        else
          with_blank_buffer(*args, &block)
        end
      end

      def haml_block? block
        eval 'defined? _hamlout', block.binding
      end

      def with_blank_buffer *args, &block
        buffer = output_buffer.dup
        output_buffer.clear and yield(*args)
        return output_buffer.dup
      ensure
        output_buffer.replace buffer
      end

      def ruby_block? block
        /\.rb$/ === eval('__FILE__', block.binding) if block
      end

      def tiny_concat markup, block = nil
        if tilt_context
          output_buffer << markup and nil
        else
          output_buffer << markup
        end
      end

      def output_buffer
        return haml_buffer.buffer if defined? haml_buffer
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
