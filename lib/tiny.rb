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
      tiny_concat Rack::Utils.escape_html(content.to_s) + "\n"
    end

    def text! content
      tiny_concat content.to_s + "\n"
    end

    def tag name, attrs = {}, &block
      html_tag name, attrs, &block
    end

    def haml_block? block
      eval 'defined? _hamlout', block.binding
    end

    def ruby_block? block
      /\.rb$/ === eval('__FILE__', block.binding)
    end

    def tiny_capture *args, &block
      __buffers << ''
      if haml_block? block
        capture_haml *args, &block
      else
        yield
      end
      __buffers.pop
    end

    def tiny_concat markup
      if __buffers.size == 1
        markup
      else
        __buffers.last << markup
      end
    end

    def __buffers
      @__buffers ||= ['']
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
      scope.tiny_concat render_tag(scope, &block)
    end

    def render_tag scope, &block
      content = scope.tiny_capture(self, &block) if block_given?
      if content
        content.gsub!(/^(?!\s*$)/, "  ")
        content.gsub!(/\A(?!$)|(?<!^|\n)\z/, "\n") 
        %{<#{tag_name}#{tag_attributes}>#{content}</#{tag_name}>}
      else
        %{<#{tag_name}#{tag_attributes} />}
      end
    end
  end
end
