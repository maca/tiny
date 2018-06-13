require 'erubis'
require 'tilt/erb'

module Tiny
  # Support for emitting explicitly the result of calls to methods that
  # take blocks. Based on the Rails ERB hack.
  #
  #   <%= my_method do %>
  #     ...
  #   <% end %>
  #
  # It overrides Tilt default Template classes for Erubis.
  #
  module Erubis
    # @see Erubis
    class ::String
      def append=(obj)
        self << obj.to_s
      end

      def append_escaped=(obj)
        self << Tiny::Helpers.sanitize(obj.to_s)
      end
    end

    # @see Erubis
    module ErubyExtensions
      def add_expr_literal(src, code)
        src << "_buf.append= #{code};"
      end

      def add_expr_escaped(src, code)
        src << "_buf.append_escaped= #{code};"
      end
    end

    # @see Erubis
    class Eruby < ::Erubis::Eruby
      include ErubyExtensions
    end

    # @see Erubis
    class EscapedEruby < ::Erubis::EscapedEruby
      include ErubyExtensions
    end

    # @see Erubis
    class ErubisTemplate < ::Tilt::ErubisTemplate
      def prepare
        engine_class = options.delete(:engine_class) || Eruby
        engine_class = EscapedEruby if options.delete(:escape_html)
        options.merge!(engine_class: engine_class)
        super
      end

      def precompiled_preamble(locals)
        [super, "__in_erb_template=true"].join("\n")
      end
    end

    Tilt.register ErubisTemplate, 'erb', 'rhtml', 'erubis'
  end
end
