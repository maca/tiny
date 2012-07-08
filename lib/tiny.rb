require 'tilt'
require 'haml'
require 'rack/utils'
require 'tiny/version'
require 'ext/tilt/template'

module Tiny
  module BufferHelper
    def local_buffer block
      block and eval('defined?(__local_buffer) and __local_buffer', block.binding)
    end
  end

  module Helpers
    def html_tag name, attrs = {}, &block
      Tag.new(name, attrs).render(self, &block)
    end

    def text content
      tiny_buffer << Rack::Utils.escape_html(content.to_s) + "\n"
    end

    def text! content
      tiny_buffer << content.to_s + "\n"
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

      def tiny_concat markup
        concat(markup) and nil
      end

      def erb_template?
        puts self.inspect
        true
      end

      def haml_template?
      end
    end


    module Generic
      attr_reader :tilt_context
      attr_accessor :tiny_buffer

      def tag name, attrs = {}, &block
        html_tag name, attrs, &block
      end

      def tiny_capture *args, &block
        if haml_template? 
          capture_haml *args, &block
        else
          with_blank_buffer *args, &block
        end
      end

      def tiny_concat markup
        # return markup if haml_template?
        tiny_buffer << markup
      end

      def with_blank_buffer *args, &block
        buffer = tiny_buffer.dup
        tiny_buffer.clear and yield(*args)
        return tiny_buffer.dup
      ensure
        tiny_buffer.replace buffer
      end

      def erb_template?
        tilt_context.is_a?(Tilt::ERBTemplate)
      end

      def haml_template?
        tilt_context.is_a?(Tilt::HamlTemplate)
      end
    end
  end

  class Tag
    include BufferHelper
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
      if scope.tiny_buffer
        scope.tiny_concat render_tag(scope, &block)
      else
        scope.tiny_buffer = '' 
        tag = scope.tiny_concat render_tag(scope, &block)
        scope.tiny_buffer = nil
        tag
      end
    end

    def render_tag scope, &block
      content = scope.tiny_capture(self, &block) if block_given?
      if content
        content.gsub!(/^(?!\s*$)/, "  ") unless scope.erb_template?
        content.gsub!(/\A(?!$)|(?<!^|\n)\z/, "\n") 
        %{<#{tag_name}#{tag_attributes}>#{content}</#{tag_name}>}
      else
        %{<#{tag_name}#{tag_attributes} />}
      end
    end
  end

  def self.registered app
    app.helpers Helpers
  end

  Sinatra.register self if defined?(Sinatra)
  ActionView::Base.send :include, Helpers if defined?(ActionView)
end
