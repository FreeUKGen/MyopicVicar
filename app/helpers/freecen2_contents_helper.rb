module Freecen2ContentsHelper

  def contents_show_percentage(pieces_online, pieces)
    percent = 0
    percent = ((pieces_online.to_f / pieces.to_f) * 100).round(1) if pieces_online > 0
    display_cell = content_tag(:td, percent.to_s)
  end

end
