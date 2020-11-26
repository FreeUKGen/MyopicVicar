module UseridDetailsHelper
  def registered(userid)
    userid.password == Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil) ? registered = "No" : registered = "Yes"
    registered
  end

  def active_user(status)
    result = 'Yes' if status
    result = 'No' unless status
    result
  end


  def list_userid_files
    case appname_downcase
    when 'freereg'
      link_to 'List Batches', by_userid_freereg1_csv_file_path(@userid), method: :get, class: 'btn   btn--small'
    when 'freecen'
      link_to 'List Batches', by_userid_freecen_csv_file_path(@userid), method: :get, class: 'btn   btn--small'
    end
  end
end
