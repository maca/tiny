require 'tilt'
require 'haml'
require 'rack/utils'
require 'tiny/version'
require 'tiny/helpers'
require 'tiny/html_tags'
require 'tiny/widget'
require 'ext/tilt/template'

module Tiny
  class SafeString < String
    def html_safe?; true end

    def concat string
      return super unless String === string
      super Helpers.sanitize string
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
        next name if val == true

        vals = [*val].map do |value|
          Helpers.sanitize value
        end

        %{#{name}="#{vals.join(' ')}"}
      end.compact.join(' ')

      " #{tag_attrs}" unless tag_attrs.empty?
    end
    
    def render &block
      return "<#{tag_name}#{tag_attributes} />" if void_tag?

      content = nil
      if block_given?
        context = eval('self', block.binding)
        content = context.tiny_capture(&block)
        content.gsub!(/^(?!\s*$)/, "  ")
        content.gsub!(/\A(?!$)|(?<!^|\n)\z/, "\n") 
      end

      "<#{tag_name}#{tag_attributes}>#{content}</#{tag_name}>"
    end

    def void_tag?
      HTMLTags.void_tags.include? tag_name
    end
  end

  Sinatra.register self if defined?(Sinatra)
  ActionView::Base.send :include, Helpers if defined?(ActionView)
end
