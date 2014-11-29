module FreeregContentsHelper
  def county_content(chapman_code)
    page = Refinery::CountyPages::CountyPage.where(:chapman_code => @chapman_code).first
    if page
      raw(page.content)
    else
      ""
    end
  end
end
