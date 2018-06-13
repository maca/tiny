require 'erubis'
require 'tilt'
require 'cgi'

require 'tiny/version'
require 'tiny/erubis'
require 'tiny/safe_string'
require 'tiny/tag'
require 'tiny/html'

module Tiny
  # Provides basic markup generation support.
  module Markup
    # Generates an HTML tag or structured HTML markup
    #
    # This method is the basis for defining html helper functions or
    # constructing html markup using pure ruby.
    #
    # HTML attributes are HTML-escaped and tags are explicitly or self
    # closed depeding on the tag name.
    #
    # Calls to markup generating methods within the content block are
    # appended to the tag's content.
    # See {Markup} and {HTML}.
    #
    # Content blocks originating from HAML or ERB templates are
    # correctly captured and handled.
    #
    # @param name [Symbol, String] The name of the tag.
    # @param attrs_or_content [Hash, String] Tag's attributes or content.
    # @param attrs [Hash] Tag's attributes if content string passed.
    # @yield Content block.
    #
    # @return [String] HTML markup
    #
    # @example Attribute mapping
    #
    #   html_tag(:link, :href => 'my-styles.css')
    #   # => <link href="my-styles.css" />
    #   html_tag(:li, 'Bicycle', :class => ['with-discount', 'in-stock'])
    #   # => <li class="with-discount in-stock">Bicycle</li>
    #   html_tag(:textarea, :disabled => true)
    #   # => <textarea disabled></textarea>
    #   html_tag(:textarea, :disabled => false)
    #   # => <textarea></textarea>
    #   html_tag(:textarea, :disabled => nil)
    #   # => <textarea></textarea>
    #
    # @example HTML-escaping
    #
    #   html_tag(:a, 'Art&Copy', :href => '/art&copy')
    #   # => <a href="/art&amp;copy">Art&amp;copy</a>
    #
    # @example Tag closing
    #
    #   html_tag(:p)    # => <p></p>
    #   html_tag(:link) # => <link />
    #
    # @example Content block
    #
    #   html_tag(:ul) do
    #     html_tag(:li, 'Cheese')
    #     html_tag(:li, 'Ham')
    #     html_tag(:li, 'Milk')
    #   end
    #   # => <ul>
    #     <li>Cheese</li>
    #     <li>Haml</li>
    #     <li>Milk</li>
    #   </ul>
    #
    #   html_tag(:p) do
    #     text 'Neque porro quisquam est qui dolorem...'
    #     'this string will be ignored'
    #   end
    #   # => <p>
    #   Neque porro quisquam est qui dolorem...
    #   </p>
    #
    # @example ERB blocks
    #
    #   !!!ruby
    #   # application_helper.rb
    #   module ApplicationHelper
    #     def my_form(url, &block)
    #       html_tag(:form, :action => url) do
    #         ...
    #         html_tag(:fieldset, &block)
    #         ...
    #       end
    #     end
    #
    #     def text_input(name, value)
    #       html_tag(:input, :type => 'text', :name => name, :value => value)
    #     end
    #   end
    #
    #   # form.erb
    #   <%= my_form '/login' do %>
    #     <%= text_input 'email', @email %>
    #   <% end %>
    #   # => <form action="/login">
    #     ...
    #     <fieldset>
    #       <input type="text" name="email" value="email@example.com" />
    #     </fieldset>
    #     ...
    #   </form>
    #
    #
    def html_tag(name, attrs_or_content = {}, attrs = nil, &block)
      append! Tag.new(name, attrs_or_content, attrs).render(&block)
    end

    # Appends an HTML coment to the content.
    #
    #   div do
    #     comment 'foo'
    #   end
    #   # => <div>
    #     <!-- foo -->
    #   </div>
    #
    # @return [SafeString] HTML content.
    #
    def comment(content)
      append! "<!-- #{content.to_s.gsub(/-(?=-)/, '- ')} -->"
    end

    # Appends a CDATA section to the content.
    #
    #   div do
    #     cdata 'foo'
    #   end
    #   # => <div>
    #   <![CDATA[foo]]>
    #   </div>
    #
    # @return [String] CDATA section.
    #
    def cdata(content)
      content = content.to_s.gsub(']]>', ']]]]><![CDATA[>')
      append! "<![CDATA[#{content}]]>"
    end

    # Appends the doctype to the content
    #
    #   with_buffer do
    #     doctype
    #     html_tag(:html) do
    #       ...
    #     end
    #   end
    #   # => <!DOCTYPE html>
    #   <html>
    #     ...
    #   </html>
    #
    # @return [String] Doctype.
    #
    def doctype
      append! "<!DOCTYPE html>"
    end
  end

  # Buffering and capturing support.
  module Buffering
    # Appends sanitized text to the content.
    #
    #   html_tag(:p) do
    #     text 'Foo &'
    #     text 'Bar'
    #   end
    #   # => <p>
    #   Foo &amp;
    #   Bar
    #   </p>
    #
    # @return [String] HTML-escaped.
    #
    def append(string)
      string = Helpers.sanitize(string)
      if working_buffer
        working_buffer << string.gsub(/(?<!^|\n)\z/, "\n")
      else
        string
      end
    end
    alias text append

    # Appends non HTML-escaped text to the content.
    #
    #   html_tag(:p) do
    #     append! 'Foo & Bar'
    #     append! '<evil>'
    #   end
    #   # => <p>
    #   Foo & Bar
    #   <evil>
    #   </p>
    #
    # Shortcut for
    #
    #   append raw(content)
    #
    # @return [SafeString] Non HTML-escaped.
    #
    def append!(content)
      append raw(content)
    end
    alias text! append!

    # Returns content that won't be HTML escaped when appended to content.
    #
    # @return [SafeString] Considered html safe.
    #
    def raw(val)
      SafeString.new val.to_s
    end

    # Buffers calls to markup generating methods.
    # @see Markup
    # @see HTML
    #
    # @example Not using #with_buffer Only the last tag is returned.
    #   def my_helper
    #     html_tag(:span, 'Foo')
    #     html_tag(:span, 'Bar')
    #   end
    #   my_helper()
    #   # => <span>Bar</span>
    #
    # @example By using #with_buffer structured markup is generated.
    #   def my_helper
    #     with_buffer do
    #       html_tag(:span, 'Foo')
    #       html_tag(:span, 'Bar')
    #     end
    #   end
    #   my_helper()
    #   # => <span>Foo</span>
    #   <span>Bar</span>
    #
    # @param args [any] n number of arguments to be passed to block evaluation.
    # @yield [*args] Content block.
    #
    # @return [String] HTML markup.
    #
    def with_buffer(*args)
      buffer_stack << ''
      yield(*args)
      buffer_stack.pop
    end

    private

    # Pushing and popping.
    def buffer_stack
      @buffer_stack ||= []
    end

    # Current buffer from the buffer stack.
    def working_buffer
      buffer_stack.last
    end
  end

  # Provides support for using Tiny helpers within a HAML template.
  module HamlTemplating
    include Buffering
    include Markup

    # Extracts a section of a HAML template or buffers a block not
    # originated from an HAML template. Akin to Rails capture method.
    #
    # @see Buffering#with_buffer
    #
    # @param args [any] n number of arguments to be passed to block evaluation.
    # @yield [*args] HAML block or content block.
    # @return [String] HTML markup.
    #
    def with_buffer(*args, &block)
      defined?(Haml) && Haml::Helpers.block_is_haml?(block) ? capture_haml(*args, &block) : super
    end
  end

  # Provides support for using Tiny helpers within an Erubis template.
  module ErubisTemplating
    include Buffering
    include Markup

    # Extracts a section of a ERB template or buffers a block not
    # originated from an ERB template. Akin to Rails capture method.
    #
    # @see Buffering#with_buffer
    #
    # @param args [any] n number of arguments to be passed to block evaluation.
    # @yield [*args] ERB block or content block.
    # @return [String] HTML markup.
    #
    def with_buffer(*args, &block)
      erb_block?(block) ? capture_erb(*args, &block) : super
    end

    # Capture a section of an ERB template.
    #
    # @param args [any] n number of arguments to be passed to block evaluation
    # @return [String] HTML markup
    # @yield [*args]
    #
    def capture_erb(*args, &block)
      output_buffer = eval('_buf', block.binding)
      buffer = output_buffer.dup
      output_buffer.clear and yield(*args)
      return output_buffer.dup
    ensure
      output_buffer.replace buffer
    end

    # Was the block defined within an ERB template?
    #
    # @param block [Proc] a Proc object
    #
    def erb_block?(block)
      block && eval('defined?(__in_erb_template)', block.binding)
    end
  end

  # Include this module anywhere you want to use markup generation, or
  # define view helpers using Tiny.
  module Helpers
    include Buffering
    include Markup
    include ErubisTemplating
    include HamlTemplating

    # Alias for {Markup#html_tag}
    #
    # @return [String] HTML markup
    #
    def tag(name, attrs_or_content = {}, attrs = nil, &block)
      html_tag name, attrs_or_content, attrs, &block
    end

    # HTML-escapes the passed value unless the content is considered
    # safe ({SafeString#html_safe? html_safe?} is implemented and
    # returns true)
    #
    # @param value [String, Object]
    # @return [String]
    #
    def self.sanitize(value)
      if value.respond_to?(:html_safe?) && value.html_safe?
        value.to_s
      else
        escape_html value.to_s
      end
    end

    def self.escape_html(html)
      CGI.escapeHTML html.to_s
    end
  end

  # Support for HTML markup generation for classes, can be included in
  # any class that is to be represented with HTML markup.
  # @see Widget
  #
  # @example
  #   class User < Model
  #     include Tiny::Rendering
  #
  #     def markup
  #       div(:id => "user-#{self.id}") do
  #         img :src => self.avatar_url
  #         dl do
  #           dt "First Name"
  #           dd self.first_name
  #           dt "Last Name"
  #           dd self.last_name
  #         end
  #       end
  #     end
  #   end
  #
  #   user = User.create(:first_name => 'Macario',
  #     :last_name => 'Ortega',
  #     :avatar_url => 'http://example.com/profile/dbg.jpeg')
  #   user.to_html
  #   # => <div id="user-1">
  #     <img src="http://example.com/profile/dbg.jpeg" />
  #     <dl>
  #       <dt>First Name</dt>
  #       <dd>Macario</dd>
  #       <dt>Last Name</dt>
  #       <dd>Ortega</dd>
  #     </dl>
  #   </div>
  #
  module Rendering
    include HTML
    include Helpers

    # Override this method with specific markup.
    #
    # @yield [self] Content block (from calling to {#render}).
    # @see Widget
    #
    def markup
      raise NotImplementedError
    end

    # Renders the html markup specified by #markup.
    #
    # @return [String] HTML markup.
    # @see Widget.
    #
    def render(&block)
      output = with_buffer do
        next markup unless block_given?
        markup do |args|
          context = eval('self', block.binding)
          append! context.instance_eval{ with_buffer(*args, &block) }
        end
      end
      SafeString.new output
    end
    alias to_html render
  end

  module ActionViewAdditions
    include Buffering
    include Markup

    # Extracts a section of a template or buffers a block not
    # originated from an template.
    #
    # @see Buffering#with_buffer
    #
    # @param args [any] n number of arguments to be passed to block evaluation.
    # @yield [*args] HAML block or content block.
    # @return [String] HTML markup.
    #
    def with_buffer(*args, &block)
      block_from_template?(block) ? capture(*args, &block) : super
    end

    # Appends sanitized text to the content.
    # @see Buffering#append
    def append(markup)
      super(markup).html_safe
    end

    # Returns true if the block was originated in an ERB or HAML template.
    def block_from_template?(block)
      block && eval('defined?(output_buffer)', block.binding) == 'local-variable'
    end
  end

  # @example
  #   class MyForm < Tiny::Widget
  #     def initialize(action)
  #       @action = action
  #     end
  #
  #     def markup
  #       form(:action => @action) do
  #         fieldset do
  #           yield(self)
  #         end
  #       end
  #     end
  #
  #     def text_input(name, value)
  #       TextInput.new(name, value).to_html
  #     end
  #   end
  #
  #   class TextInput < Tiny::Widget
  #     def initialize(name, value)
  #       @name, @value = name, value
  #     end
  #
  #     def markup
  #       label(@name.capitalize, :for => @name)
  #       input(:type => 'text', :id => @name, :name => @name, :value => @value)
  #     end
  #   end
  #
  #   def my_form(action, &block)
  #     MyForm.new(action).to_html(&block)
  #   end
  #
  #   my_form('/login') do |form|
  #     append! form.text_input 'email', 'email@example.com'
  #   end
  #   # => <form action="/login">
  #     ...
  #     <fieldset>
  #       <label for="email">Email</label>
  #       <input type="text" id="email" name="email" value="email@example.com" />
  #     </fieldset>
  #     ...
  #   </form>
  #
  #   # from template
  #   <%= my_form('/login') do |form| %>
  #     <%= form.text_input 'email', 'email@example.com' %>
  #   <% end %>
  #   # => <form action="/login">
  #     ...
  #     <fieldset>
  #       <label for="email">Email</label>
  #       <input type="text" id="email" name="email" value="email@example.com" />
  #     </fieldset>
  #     ...
  #   </form>
  #
  # @see Rendering
  #
  class Widget
    include Rendering
  end

  ActionView::Base.send :include, ActionViewAdditions if defined?(ActionView)
end
