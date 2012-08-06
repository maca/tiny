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
          EscapeUtils.escape_html value.to_s
        end
      end
    end

    module TextHelpers
      def html_tag name, attrs_or_content = {}, attrs = nil, &block
        tiny_concat Tag.new(name, attrs_or_content, attrs).render(&block)
      end

      def text content
        tiny_concat Helpers.sanitize(content).gsub(/(?<!^|\n)\z/, "\n")
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

    module RubyHelpers
      include TextHelpers
      alias :tag :html_tag

      def raw val
        SafeString.new val.to_s
      end

      def markup *args, &block
        buffer_stack << ''
        yield *args
        buffer_stack.pop
      end

      def tiny_concat markup
        working_buffer ? working_buffer.concat(markup).html_safe : markup.html_safe
      end

      def erb_block? block
        block && eval('defined?(__in_erb_template)', block.binding)
      end

      private
      def buffer_stack
        @buffer_stack ||= []
      end

      def working_buffer
        buffer_stack.last
      end
    end

    module ActionViewHelpers
      include RubyHelpers

      def markup *args, &block
        block_from_template?(block) ? capture(*args, &block) : super
      end

      def block_from_template? block
        block && eval('defined?(output_buffer)', block.binding) == 'local-variable'
      end
    end 

    module HamlHelpers
      include RubyHelpers

      def markup *args, &block
        Haml::Helpers.block_is_haml?(block) ? capture_haml(*args, &block) : super
      end
    end

    module ERBHelpers
      include RubyHelpers

      def markup *args, &block
        erb_block?(block) ? capture_erb(*args, &block) : super
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
