module Freecen2PlaceSourcesHelper

  def destroy_freecen2_place_source_link(freecen2_place_source, type)
    used_cnt = Freecen2Place.where(source: freecen2_place_source.source).count
    if used_cnt.positive?
      confirm_message  = "Are you sure you want to destroy this Source as it is used by #{used_cnt} FreeCen2 Place records?"
    else
      confirm_message  = 'Are you sure you want to destroy this Source?'
    end
    return link_to 'Destroy Source', freecen2_place_source_path(freecen2_place_source), method: :delete, data: { confirm: confirm_message }, :class => 'btn btn--small' if type == 'button'
    return link_to 'Destroy', freecen2_place_source_path(freecen2_place_source), method: :delete, data: { confirm: confirm_message } if type != 'button'
  end

  def edit_freecen2_place_source_link(freecen2_place_source, type)
    used_cnt = Freecen2Place.where(source: freecen2_place_source.source).count
    if used_cnt.positive?
      confirm_message  = "Are you sure you want to edit this Source as it is used by #{used_cnt} FreeCen2 Place records?"
      return link_to 'Edit Source', edit_freecen2_place_source_path(freecen2_place_source), method: :get, data: { confirm: confirm_message }, :class => 'btn btn--small' if type == 'button'
      return link_to 'Edit', edit_freecen2_place_source_path(freecen2_place_source), method: :get, data: { confirm: confirm_message }  if type != 'button'
    else
      return link_to 'Edit Source', edit_freecen2_place_source_path(freecen2_place_source), method: :get, :class => 'btn btn--small' if type == 'button'
      return link_to 'Edit', edit_freecen2_place_source_path(freecen2_place_source), method: :get if type != 'button'
    end
  end

end
