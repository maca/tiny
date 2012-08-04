require 'erubis'
require 'tilt/erb'

class String
  def append= obj
    self << obj.to_s
  end

  def append_escaped= obj
    self << Tiny::Helpers.sanitize(obj.to_s)
  end
end

module Tiny
  module Erubis
    module ErubyExtensions
      def add_expr_literal src, code
        src << "_buf.append= #{code};"
      end

      def add_expr_escaped src, code
        src << "_buf.append_escaped= #{code};"
      end
    end

    class Eruby < ::Erubis::Eruby
      include ErubyExtensions
    end

    class EscapedEruby < ::Erubis::EscapedEruby
      include ErubyExtensions
    end

    class ErubisTemplate < ::Tilt::ErubisTemplate
      def prepare
        engine_class = options.delete(:engine_class) || Eruby
        engine_class = EscapedEruby if options.delete(:escape_html)
        options.merge!(:engine_class => engine_class)
        super
      end

      def precompiled_preamble locals
        [super, "@erb_buffer=_buf", "__in_erb_template=true"].join("\n")
      end
    end

    Tilt.register ErubisTemplate, 'erb', 'rhtml', 'erubis'
  end
end
