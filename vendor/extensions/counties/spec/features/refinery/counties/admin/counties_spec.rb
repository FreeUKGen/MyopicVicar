# encoding: utf-8
require "spec_helper"

describe Refinery do
  describe "Counties" do
    describe "Admin" do
      describe "counties" do
        refinery_login_with :refinery_user

        describe "counties list" do
          before do
            FactoryGirl.create(:county, :county => "UniqueTitleOne")
            FactoryGirl.create(:county, :county => "UniqueTitleTwo")
          end

          it "shows two items" do
            visit refinery.counties_admin_counties_path
            page.should have_content("UniqueTitleOne")
            page.should have_content("UniqueTitleTwo")
          end
        end

        describe "create" do
          before do
            visit refinery.counties_admin_counties_path

            click_link "Add New County"
          end

          context "valid data" do
            it "should succeed" do
              fill_in "County", :with => "This is a test of the first string field"
              click_button "Save"

              page.should have_content("'This is a test of the first string field' was successfully added.")
              Refinery::Counties::County.count.should == 1
            end
          end

          context "invalid data" do
            it "should fail" do
              click_button "Save"

              page.should have_content("County can't be blank")
              Refinery::Counties::County.count.should == 0
            end
          end

          context "duplicate" do
            before { FactoryGirl.create(:county, :county => "UniqueTitle") }

            it "should fail" do
              visit refinery.counties_admin_counties_path

              click_link "Add New County"

              fill_in "County", :with => "UniqueTitle"
              click_button "Save"

              page.should have_content("There were problems")
              Refinery::Counties::County.count.should == 1
            end
          end

        end

        describe "edit" do
          before { FactoryGirl.create(:county, :county => "A county") }

          it "should succeed" do
            visit refinery.counties_admin_counties_path

            within ".actions" do
              click_link "Edit this county"
            end

            fill_in "County", :with => "A different county"
            click_button "Save"

            page.should have_content("'A different county' was successfully updated.")
            page.should have_no_content("A county")
          end
        end

        describe "destroy" do
          before { FactoryGirl.create(:county, :county => "UniqueTitleOne") }

          it "should succeed" do
            visit refinery.counties_admin_counties_path

            click_link "Remove this county forever"

            page.should have_content("'UniqueTitleOne' was successfully removed.")
            Refinery::Counties::County.count.should == 0
          end
        end

      end
    end
  end
end
