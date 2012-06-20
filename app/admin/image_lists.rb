require 'chapman_code'
ActiveAdmin.register ImageList do
    form do |f|
      f.inputs "Details" do
        f.input :name
        f.input :start_date
        f.input :difficulty, :as => :select, :collection => { "Beginner" => 0, "Intermediate" => 1, "Advanced" => 2 }
        f.input :chapman_code, :as => :select, :collection => ChapmanCode::select_hash_with_parenthetical_codes
      end
      f.buttons
    end

end
