# encoding: utf-8
require "spec_helper"

describe Refinery do
  describe "CountyPages" do
    describe "Admin" do
      describe "county_pages" do
        refinery_login_with :refinery_user

        describe "county_pages list" do
          before do
            FactoryGirl.create(:county_page, :name => "UniqueTitleOne")
            FactoryGirl.create(:county_page, :name => "UniqueTitleTwo")
          end

          it "shows two items" do
            visit refinery.county_pages_admin_county_pages_path
            page.should have_content("UniqueTitleOne")
            page.should have_content("UniqueTitleTwo")
          end
        end

        describe "create" do
          before do
            visit refinery.county_pages_admin_county_pages_path

            click_link "Add New County Page"
          end

          context "valid data" do
            it "should succeed" do
              fill_in "Name", :with => "This is a test of the first string field"
              click_button "Save"

              page.should have_content("'This is a test of the first string field' was successfully added.")
              Refinery::CountyPages::CountyPage.count.should == 1
            end
          end

          context "invalid data" do
            it "should fail" do
              click_button "Save"

              page.should have_content("Name can't be blank")
              Refinery::CountyPages::CountyPage.count.should == 0
            end
          end

          context "duplicate" do
            before { FactoryGirl.create(:county_page, :name => "UniqueTitle") }

            it "should fail" do
              visit refinery.county_pages_admin_county_pages_path

              click_link "Add New County Page"

              fill_in "Name", :with => "UniqueTitle"
              click_button "Save"

              page.should have_content("There were problems")
              Refinery::CountyPages::CountyPage.count.should == 1
            end
          end

        end

        describe "edit" do
          before { FactoryGirl.create(:county_page, :name => "A name") }

          it "should succeed" do
            visit refinery.county_pages_admin_county_pages_path

            within ".actions" do
              click_link "Edit this county page"
            end

            fill_in "Name", :with => "A different name"
            click_button "Save"

            page.should have_content("'A different name' was successfully updated.")
            page.should have_no_content("A name")
          end
        end

        describe "destroy" do
          before { FactoryGirl.create(:county_page, :name => "UniqueTitleOne") }

          it "should succeed" do
            visit refinery.county_pages_admin_county_pages_path

            click_link "Remove this county page forever"

            page.should have_content("'UniqueTitleOne' was successfully removed.")
            Refinery::CountyPages::CountyPage.count.should == 0
          end
        end

      end
    end
  end
end
