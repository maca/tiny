module Tiny
  # A {SafeString} will not be HTML-escaped when appended to {Tag} or
  # {Widget} content, whereas a String will be.
  # @see Buffering#raw
  # @see Buffering#concat!
  # @see Buffering#concat
  #
  class SafeString < String
    def html_safe?; true end

    def concat(string)
      return super unless String === string
      super Helpers.sanitize string
    end
  end
end
