require 'spec_helper'

describe "freereg1_csv_files/index" do
  before(:each) do
    assign(:freereg1_csv_files, [
      stub_model(Freereg1CsvFile,
        :dir_name => "Dir Name",
        :file_name => "File Name",
        :transcriber_email => "Transcriber Email",
        :transcriber_name => "Transcriber Name",
        :transcriber_syndicate => "Transcriber Syndicate",
        :transcription_date => "Transcription Date",
        :record_type => "Record Type",
        :credit_name => "Credit Name",
        :credit_email => "Credit Email",
        :first_comment => "First Comment",
        :second_comment => "Second Comment"
      ),
      stub_model(Freereg1CsvFile,
        :dir_name => "Dir Name",
        :file_name => "File Name",
        :transcriber_email => "Transcriber Email",
        :transcriber_name => "Transcriber Name",
        :transcriber_syndicate => "Transcriber Syndicate",
        :transcription_date => "Transcription Date",
        :record_type => "Record Type",
        :credit_name => "Credit Name",
        :credit_email => "Credit Email",
        :first_comment => "First Comment",
        :second_comment => "Second Comment"
      )
    ])
  end

  it "renders a list of freereg1_csv_files" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Dir Name".to_s, :count => 2
    assert_select "tr>td", :text => "File Name".to_s, :count => 2
    assert_select "tr>td", :text => "Transcriber Email".to_s, :count => 2
    assert_select "tr>td", :text => "Transcriber Name".to_s, :count => 2
    assert_select "tr>td", :text => "Transcriber Syndicate".to_s, :count => 2
    assert_select "tr>td", :text => "Transcription Date".to_s, :count => 2
    assert_select "tr>td", :text => "Record Type".to_s, :count => 2
    assert_select "tr>td", :text => "Credit Name".to_s, :count => 2
    assert_select "tr>td", :text => "Credit Email".to_s, :count => 2
    assert_select "tr>td", :text => "First Comment".to_s, :count => 2
    assert_select "tr>td", :text => "Second Comment".to_s, :count => 2
  end
end
