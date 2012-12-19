require 'spec_helper'

describe "freereg1_csv_files/show" do
  before(:each) do
    @freereg1_csv_file = assign(:freereg1_csv_file, stub_model(Freereg1CsvFile,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Dir Name/)
    rendered.should match(/File Name/)
    rendered.should match(/Transcriber Email/)
    rendered.should match(/Transcriber Name/)
    rendered.should match(/Transcriber Syndicate/)
    rendered.should match(/Transcription Date/)
    rendered.should match(/Record Type/)
    rendered.should match(/Credit Name/)
    rendered.should match(/Credit Email/)
    rendered.should match(/First Comment/)
    rendered.should match(/Second Comment/)
  end
end
