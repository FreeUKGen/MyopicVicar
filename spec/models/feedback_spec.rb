require 'spec_helper'

describe Feedback do
  let(:source_image) { Rails.root.join('public_site_specific', 'freecen', 'favicon-16x16.png') }

  def tmp_image(name)
    destination = File.join(Rails.root, 'tmp', name)
    FileUtils.cp(source_image, destination)
    destination
  end

  before(:each) do
    Feedback.delete_all
  end

  after(:all) do
    Dir.glob(File.join(Rails.root, 'tmp', 'feedback_upload_*.png')).each { |f| File.delete(f) }
  end

  it 'stores a single screenshot' do
    file = tmp_image('feedback_upload_single.png')
    feedback = Feedback.new(title: 'Issue', body: 'Details')
    feedback.screenshot = CarrierWave::SanitizedFile.new(file)
    feedback.save!
    feedback.reload

    expect(feedback.read_attribute(:screenshot)).to eq('feedback_upload_single.png')
    expect(feedback.screenshot_location).to eq("uploads/feedback/screenshot/#{feedback.id}/feedback_upload_single.png")
    expect(feedback.attachment_urls).to eq(["/uploads/feedback/screenshot/#{feedback.id}/feedback_upload_single.png"])
    expect(feedback.attachment_file_paths).to eq([File.join(Rails.root, 'public', 'uploads', 'feedback', 'screenshot', feedback.id.to_s, 'feedback_upload_single.png')])
  end

  it 'stores multiple screenshots' do
    file_one = tmp_image('feedback_upload_a.png')
    file_two = tmp_image('feedback_upload_b.png')
    feedback = Feedback.new(title: 'Issue', body: 'Details')
    feedback.screenshots = [CarrierWave::SanitizedFile.new(file_one), CarrierWave::SanitizedFile.new(file_two)]
    feedback.save!
    feedback.reload

    expect(feedback.read_attribute(:screenshots)).to eq(['feedback_upload_a.png', 'feedback_upload_b.png'])
    expect(feedback.attachment_urls).to eq(
      ["/uploads/feedback/screenshots/#{feedback.id}/feedback_upload_a.png",
       "/uploads/feedback/screenshots/#{feedback.id}/feedback_upload_b.png"]
    )
    expect(feedback.attachment_file_paths.length).to eq(2)
    feedback.attachment_file_paths.each { |path| expect(File.file?(path)).to be_truthy }
    expect(feedback.screenshot_location).to eq("uploads/feedback/screenshots/#{feedback.id}/feedback_upload_a.png")
    expect(feedback.attachments_present?).to be_truthy
  end

  it 'reports no attachments when none are present' do
    feedback = Feedback.new(title: 'Issue', body: 'Details')
    feedback.save!

    expect(feedback.attachments_present?).to be_falsey
    expect(feedback.attachment_urls).to eq([])
    expect(feedback.attachment_file_paths).to eq([])
  end

  it 'does not recompute screenshot_location on saves unrelated to attachments' do
    file = tmp_image('feedback_upload_untouched.png')
    feedback = Feedback.new(title: 'Issue', body: 'Details')
    feedback.screenshot = CarrierWave::SanitizedFile.new(file)
    feedback.save!
    feedback.reload

    expect(feedback).not_to receive(:computed_screenshot_location)
    feedback.update_attribute(:title, 'Updated title')
  end

  it 'includes a link to every attachment in the body when linking attachments' do
    file_one = tmp_image('feedback_upload_link_a.png')
    file_two = tmp_image('feedback_upload_link_b.png')
    feedback = Feedback.new(title: 'Issue', body: 'Details')
    feedback.screenshots = [CarrierWave::SanitizedFile.new(file_one), CarrierWave::SanitizedFile.new(file_two)]
    feedback.save!
    feedback.reload

    feedback.add_link_to_attachment
    feedback.reload

    feedback.attachment_urls.each do |url|
      expect(feedback.body).to include(url)
    end
  end

  it 'does not attempt to link attachments when none are present' do
    feedback = Feedback.new(title: 'Issue', body: 'Details')
    feedback.save!

    expect(feedback).not_to receive(:update_attribute)
    feedback.add_link_to_attachment
  end
end