module EmbargoRulesHelper
  def user(id)
    user = UseridDetail.find_by(_id: id)
    user.userid
  end
end
