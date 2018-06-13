module ListHelper
  def list(&block)
    html_tag(:ul, &block)
  end

  def item_content(num)
    html_tag(:li) do
      html_tag(:a) do
        text((num + 64).chr)
        html_tag(:span) { text num }
      end
    end
  end
end
