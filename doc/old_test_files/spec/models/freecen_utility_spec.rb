require 'spec_helper'
RSpec.describe FreecenUtility, type: :model do
  subject { described_class.display_date_and_time }
  let(:record) { { value: Time.new(2002) } }
  let(:current_time) { Time.now }
  let(:current_date) { Date.today }
  let(:formatted_current_date) { current_date.to_formatted_s(:long_ordinal) }

  describe '.document_db_update' do
    it 'updates the value to Time.now' do
      allow(described_class).to receive(:get_freecen_update_doc).and_return(record)
      expect{ described_class.document_db_update }.to change { record[:value] }.from(Time.new(2002)).to be_truthy
    end
  end

  describe '.display_date_and_time' do
    context 'when document does not exist' do
      specify do
        allow(described_class).to receive(:freecen_update_document).and_return(nil)
        expect(subject).to be_nil
      end
    end
    context "when document exists" do
      it "formats date" do        
        allow(described_class).to receive(:get_update_date).and_return(current_time)
        expect(subject).to include(formatted_current_date)        
      end
    end
  end
end
