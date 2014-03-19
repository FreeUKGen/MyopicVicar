require 'spec_helper'

module Refinery
  module Counties
    describe County do
      describe "validations" do
        subject do
          FactoryGirl.create(:county,
          :county => "Refinery CMS")
        end

        it { should be_valid }
        its(:errors) { should be_empty }
        its(:county) { should == "Refinery CMS" }
      end
    end
  end
end
