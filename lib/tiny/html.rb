module Tiny
  module HTML
    @content_tags = []
    @void_tags    = []

    class << self
      # Void tag names.
      # Tags that should have no content.
      # @return [Array]
      attr_reader :content_tags

      # Content tag names.
      # Tags that can have content.
      # @return [Array]
      attr_reader :void_tags

      private

      # @macro tag_def
      #  @method $1(attrs_or_content = {}, attrs = nil, &block)
      #  Shortcut for {Markup#html_tag html_tag}(:$1)
      #
      #  @param attrs_or_content [Hash, String] Tag's attributes or content.
      #  @param attrs [Hash] Tag's attributes if content string passed.
      #  @yield Content block.
      #  @return [String] HTML markup
      #
      #  @see Markup#html_tag
      #
      def tag_def(tag_name, void_tag = false)
        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{tag_name} *args, &block
            html_tag "#{tag_name}", *args, &block
          end
        RUBY
        void_tag ? @void_tags.push(tag_name) : @content_tags.push(tag_name)
      end
    end

    tag_def 'area',  :void
    tag_def 'base',  :void
    tag_def 'br',    :void
    tag_def 'col',   :void
    tag_def 'hr',    :void
    tag_def 'img',   :void
    tag_def 'input', :void
    tag_def 'link',  :void
    tag_def 'meta',  :void
    tag_def 'param', :void

    # html 5 tags
    tag_def 'embed', :void
    tag_def 'article'
    tag_def 'aside'
    tag_def 'audio'
    tag_def 'bdi'
    tag_def 'canvas'
    tag_def 'command'
    tag_def 'datalist'
    tag_def 'details'
    tag_def 'figcaption'
    tag_def 'figure'
    tag_def 'header'
    tag_def 'hgroup'
    tag_def 'keygen'
    tag_def 'mark'
    tag_def 'meter'
    tag_def 'nav'
    tag_def 'output'
    tag_def 'progress'
    tag_def 'section'
    tag_def 'source'
    tag_def 'summary'
    tag_def 'track'
    tag_def 'video'
    tag_def 'wbr'

    # common tags
    tag_def 'a'
    tag_def 'abbr'
    tag_def 'address'

    tag_def 'b'
    tag_def 'bdo'
    tag_def 'big'
    tag_def 'blockquote'
    tag_def 'body'
    tag_def 'button'

    tag_def 'caption'
    tag_def 'cite'
    tag_def 'code'
    tag_def 'colgroup'

    tag_def 'dd'
    tag_def 'del'
    tag_def 'dfn'
    tag_def 'div'
    tag_def 'dl'
    tag_def 'dt'

    tag_def 'em'

    tag_def 'fieldset'
    tag_def 'footer'
    tag_def 'form'

    tag_def 'h1'
    tag_def 'h2'
    tag_def 'h3'
    tag_def 'h4'
    tag_def 'h5'
    tag_def 'h6'
    tag_def 'head'
    tag_def 'html'

    tag_def 'i'
    tag_def 'iframe'
    tag_def 'ins'

    tag_def 'kbd'

    tag_def 'label'
    tag_def 'legend'
    tag_def 'li'

    tag_def 'map'

    tag_def 'noscript'

    tag_def 'object'
    tag_def 'ol'
    tag_def 'optgroup'
    tag_def 'option'

    tag_def 'p'
    tag_def 'pre'

    tag_def 'q'

    tag_def 'rp'
    tag_def 'rt'
    tag_def 'ruby'

    tag_def 's'
    tag_def 'samp'
    tag_def 'script'
    tag_def 'select'
    tag_def 'small'
    tag_def 'span'
    tag_def 'strike'
    tag_def 'strong'
    tag_def 'style'
    tag_def 'sub'
    tag_def 'sup'

    tag_def 'table'
    tag_def 'tbody'
    tag_def 'td'
    tag_def 'textarea'
    tag_def 'tfoot'
    tag_def 'th'
    tag_def 'thead'
    tag_def 'time'
    tag_def 'title'
    tag_def 'tr'
    tag_def 'tt'

    tag_def 'u'
    tag_def 'ul'

    tag_def 'var'
  end
end
