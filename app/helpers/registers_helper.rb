module RegistersHelper
  def which_embargo_rule_link(rules)
    if rules
      link_to 'Embargo Rules', embargo_rules_path(county: @county, place: @place, church: @church, register: @register),
        method: :get, :class => "btn   btn--small"
    else
      link_to 'Create New Embargo Rule', new_embargo_rule_path(county: @county, place: @place, church: @church, register: @register),
        method: :get, :class => "btn   btn--small"
    end
  end

  def which_image_server_link(server)
    if server
      link_to 'Image Sources', show_image_server_register_path(@register), method: :get, :class => "btn   btn--small"
    else
      link_to 'Create Image Server', create_image_server_register_path(@register), method: :get, :class => "btn   btn--small"
    end
  end
end
