module ListHelper
  def list &block
    html_tag :ul, &block
  end

  def item_content a, b
    html_tag(:a) do
      text a
      html_tag(:span) { text b }
    end
  end
end
