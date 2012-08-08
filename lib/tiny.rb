require 'erubis'
require 'haml'
require 'tilt'
require 'escape_utils'

require 'tiny/version'
require 'tiny/erubis'
require 'tiny/safe_string'
require 'tiny/tag'
require 'tiny/html'

module Tiny
  module Markup
    def html_tag name, attrs_or_content = {}, attrs = nil, &block
      tiny_concat Tag.new(name, attrs_or_content, attrs).render(&block)
    end

    def text content
      tiny_concat Helpers.sanitize(content)
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
      text! "<!DOCTYPE html>"
    end

    def raw val
      SafeString.new val.to_s
    end
  end

  module Buffering
    def markup *args, &block
      buffer_stack << ''
      yield *args
      buffer_stack.pop
    end

    def tiny_concat markup
      if working_buffer 
        working_buffer << markup.gsub(/(?<!^|\n)\z/, "\n")
      else
        markup
      end
    end

    private
    def buffer_stack
      @buffer_stack ||= []
    end

    def working_buffer
      buffer_stack.last
    end
  end

  module HamlTemplating
    include Buffering
    include Markup

    def markup *args, &block
      ::Haml::Helpers.block_is_haml?(block) ? capture_haml(*args, &block) : super
    end
  end

  module ERBTemplating
    include Buffering
    include Markup

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

    def erb_block? block
      block && eval('defined?(__in_erb_template)', block.binding)
    end
  end

  module Helpers
    include Buffering
    include Markup
    include ERBTemplating
    include HamlTemplating

    alias :tag :html_tag

    def self.sanitize value
      if value.respond_to?(:html_safe?) && value.html_safe?
        value.to_s
      else
        EscapeUtils.escape_html value.to_s
      end
    end
  end

  module Rendering
    include HTML
    include Helpers

    def content
      raise NotImplementedError
    end

    def render &block
      markup do
        next content unless block_given?
        content do
          context = eval('self', block.binding)
          text! context.instance_eval{ markup(&block) } 
        end
      end
    end
    alias to_html render
  end

  module ActionViewAdditions
    include Buffering
    include Markup

    def markup *args, &block
      block_from_template?(block) ? capture(*args, &block) : super
    end

    def tiny_concat markup
      super(markup).html_safe
    end

    def block_from_template? block
      block && eval('defined?(output_buffer)', block.binding) == 'local-variable'
    end
  end 

  class Widget
    include Rendering
  end

  Sinatra.register self if defined?(Sinatra)
  ActionView::Base.send :include, ActionViewAdditions if defined?(ActionView)
end
