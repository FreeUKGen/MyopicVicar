class ChurchNamesController < ApplicationController
  def index
    @church_names = ChurchName.where.sort(:chapman_code, :parish, :church)
  end
end
