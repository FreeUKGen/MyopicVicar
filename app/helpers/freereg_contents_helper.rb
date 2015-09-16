module FreeregContentsHelper
  def county_content(chapman_code)
    page = Refinery::CountyPages::CountyPage.where(:chapman_code => @chapman_code).first
    if page
      raw(page.content)
    else
      ""
    end
  end
  def credit(register)
    if register.credit.present?
      field = register.credit
    else
      field = nil
    end
    field
  end
  def credit_files(files)
    people = Array.new
    field = nil
    if files.present?
      files.each_value do |file|
        people << file["credit_name"] unless file["credit_name"].blank?
      end
      people = people.uniq
      field = people.join(',').to_s
    end
    field
  end
end
