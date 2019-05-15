module FreecenPiecesHelper
  #return hyperlink to map lat,long (unless 0,0 or 60,0; then just return text)
  def map_link_helper(text, lat, long, zoom=10, title='Show on Map')
    return text if (0.0==lat.to_f || 60.0==lat.to_f) && 0.0==long.to_f
    if(true)#google maps
      return raw '<a href="https://google.com/maps/place/'+(lat.to_f.to_s)+','+(long.to_f.to_s)+'/@'+(lat.to_f.to_s)+','+(long.to_f.to_s)+','+(zoom.to_i.to_s)+'z" target="_blank" title="'+(title.to_s)+'">'+(text.to_s)+'</a>'
    else#openstreetmap.org
      return raw '<a href="https://www.openstreetmap.org/?mlat='+(lat.to_f.to_s)+'&mlon='+(long.to_f.to_s)+'#map='+(zoom.to_i.to_s)+'/'+(lat.to_f.to_s)+'/'+(long.to_f.to_s)+'" target="_blank" title="'+(title.to_s)+'">'+(text.to_s)+'</a>'
    end
  end
end
