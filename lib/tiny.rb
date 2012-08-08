require 'erubis'
require 'haml'
require 'tilt'
require 'escape_utils'
require 'tiny/version'
require 'tiny/helpers'
require 'tiny/safe_string'
require 'tiny/html'
require 'tiny/widget'
require 'tiny/erubis'

module Tiny

  class Tag
    attr_reader :tag_name, :attrs
    def initialize tag_name, aoc = {}, attrs = nil
      @attrs, @content =
        Hash === aoc && attrs.nil?? [aoc] : [attrs || {}, aoc]
      @content  = Helpers.sanitize(@content) if @content 
      @tag_name = tag_name
    end
    
    def tag_attributes
      tag_attrs = attrs.map do |name, val|
        next if val.nil? || val == []
        next name if val == true

        vals = [*val].map do |value|
          EscapeUtils.escape_html value.to_s, false
        end

        %{#{name}="#{vals.join(' ')}"}
      end.compact.join(' ')

      " #{tag_attrs}" unless tag_attrs.empty?
    end

    def render &block
      if void_tag?
        "<#{tag_name}#{tag_attributes} />"
      else
        content = @content 
        if block_given?
          context = eval('self', block.binding)
          content = context.markup(&block)
          content.gsub!(/^(?!\s*$)/, "  ")
          content.gsub!(/\A(?!$)|(?<!^|\n)\z/, "\n") 
        end

        "<#{tag_name}#{tag_attributes}>#{content}</#{tag_name}>"
      end
    end

    def void_tag?
      HTML.void_tags.include? tag_name
    end
  end

  Sinatra.register self if defined?(Sinatra)
  ActionView::Base.send :include, Helpers if defined?(ActionView)
end
