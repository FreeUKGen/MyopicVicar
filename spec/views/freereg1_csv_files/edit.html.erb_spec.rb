require 'spec_helper'

describe "freereg1_csv_files/edit" do
  before(:each) do
    @freereg1_csv_file = assign(:freereg1_csv_file, stub_model(Freereg1CsvFile,
      :dir_name => "MyString",
      :file_name => "MyString",
      :transcriber_email => "MyString",
      :transcriber_name => "MyString",
      :transcriber_syndicate => "MyString",
      :transcription_date => "MyString",
      :record_type => "MyString",
      :credit_name => "MyString",
      :credit_email => "MyString",
      :first_comment => "MyString",
      :second_comment => "MyString"
    ))
  end

  it "renders the edit freereg1_csv_file form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => freereg1_csv_files_path(@freereg1_csv_file), :method => "post" do
      assert_select "input#freereg1_csv_file_dir_name", :name => "freereg1_csv_file[dir_name]"
      assert_select "input#freereg1_csv_file_file_name", :name => "freereg1_csv_file[file_name]"
      assert_select "input#freereg1_csv_file_transcriber_email", :name => "freereg1_csv_file[transcriber_email]"
      assert_select "input#freereg1_csv_file_transcriber_name", :name => "freereg1_csv_file[transcriber_name]"
      assert_select "input#freereg1_csv_file_transcriber_syndicate", :name => "freereg1_csv_file[transcriber_syndicate]"
      assert_select "input#freereg1_csv_file_transcription_date", :name => "freereg1_csv_file[transcription_date]"
      assert_select "input#freereg1_csv_file_record_type", :name => "freereg1_csv_file[record_type]"
      assert_select "input#freereg1_csv_file_credit_name", :name => "freereg1_csv_file[credit_name]"
      assert_select "input#freereg1_csv_file_credit_email", :name => "freereg1_csv_file[credit_email]"
      assert_select "input#freereg1_csv_file_first_comment", :name => "freereg1_csv_file[first_comment]"
      assert_select "input#freereg1_csv_file_second_comment", :name => "freereg1_csv_file[second_comment]"
    end
  end
end
