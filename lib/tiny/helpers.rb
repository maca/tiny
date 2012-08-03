module Tiny
  module Helpers
    class << self
      def included base
        if defined?(ActionView) && base.ancestors.include?(ActionView::Base)
          base.send :include, ActionViewHelpers
        else
          base.send :include, RubyHelpers
          base.send :include, ERBHelpers
          base.send :include, HamlHelpers
        end
      end

      def sanitize value
        if value.respond_to?(:html_safe?) && value.html_safe?
          value.to_s
        else
          Rack::Utils.escape_html value.to_s
        end
      end
    end

    module TextHelpers
      def html_tag name, attrs_or_content = {}, attrs = nil, &block
        if Hash === attrs_or_content && attrs.nil?
          tiny_concat Tag.new(name, attrs_or_content).render(&block)
        else
          tiny_concat Tag.new(name, attrs || {}).render { text attrs_or_content }
        end
      end

      def text content
        tiny_concat Helpers.sanitize(content) + "\n"
      end

      def text! content
        text raw(content)
      end

      def comment content
        text! "<!-- #{content.to_s.gsub(/-(?=-)/, '- ')} -->"
      end

      def cdata content
        content = content.to_s.gsub(']]>', ']]]]><![CDATA[>')
        text! "<![CDATA[#{content}]]>"
      end

      def doctype
        "<!DOCTYPE html>"
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

    module RubyHelpers
      include TextHelpers
      alias :tag :html_tag

      def raw val
        SafeString.new val.to_s
      end

      def tiny_capture *args, &block
        buffer_stack << ''
        yield *args
        buffer_stack.pop
      end

      def tiny_concat markup
        working_buffer ? working_buffer.concat(markup) : markup
      end

      def markup &block
        tiny_capture(&block)
      end

      private
      def buffer_stack
        @buffer_stack ||= []
      end

      def working_buffer
        buffer_stack.last
      end
    end

    module HamlHelpers
      include RubyHelpers

      def tiny_capture *args, &block
        Haml::Helpers.block_is_haml?(block) ? capture_haml(*args, &block) : super
      end
    end

    module ERBHelpers
      include RubyHelpers

      def tiny_capture *args, &block
        erb_block?(block) ? capture_erb(&block) : super
      end

      def erb_block? block
        block && eval('defined?(__in_erb_template)', block.binding)
      end

      def capture_erb *args, &block
        output_buffer = eval('_buf', block.binding)
        buffer = output_buffer.dup
        output_buffer.clear and yield(*args)
        return output_buffer.dup
      ensure
        output_buffer.replace buffer
      end
    end
  end
end
