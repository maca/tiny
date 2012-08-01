module Tiny
  class Widget
    include HTMLTags
    include Tiny::Helpers

    def render
      widget do
        content
      end
    end
  end
end
