require 'spec_helper'
require 'extract_collection_unique_names'

describe ExtractCollectionUniqueNames do
  def clean_extractor_records
    RegisterUniqueName.delete_all
    Source.delete_all
    Freereg1CsvFile.delete_all
    Register.delete_all
    Church.delete_all
    Place.delete_all
  end

  before(:each) { clean_extractor_records }
  after(:each) { clean_extractor_records }

  def create_processed_register(names)
    place = Place.create!(place_name: 'Test Place', chapman_code: 'CHI', latitude: 51, longitude: 0, data_present: true)
    church = Church.create!(church_name: 'Test Church', place_id: place.id)
    register = Register.create!(register_type: 'BA', church_id: church.id)
    Freereg1CsvFile.collection.insert_one(_id: BSON::ObjectId.new, register_id: register.id)
    allow_any_instance_of(Freereg1CsvFile).to receive(:get_unique_names).and_return(names)
    register
  end

  def create_unprocessed_register
    place = Place.create!(place_name: 'Unprocessed Place', chapman_code: 'CHI', latitude: 51, longitude: 0)
    church = Church.create!(church_name: 'Unprocessed Church', place_id: place.id)
    Register.create!(church_id: church.id)
  end

  it 'creates a register summary from recognised names' do
    register = create_processed_register("Person's Forename" => ['Jane'], "Person's Surname" => ['Doe'])

    described_class.process(1)

    summary = RegisterUniqueName.find_by(register_id: register.id)
    expect(summary.unique_forenames).to eq(['Jane'])
    expect(summary.unique_surnames).to eq(['Doe'])
  end

  it 'updates an existing register summary when names change' do
    register = create_processed_register("Person's Forename" => ['Alice'], "Person's Surname" => ['Smith'])
    summary = RegisterUniqueName.create!(register_id: register.id, unique_forenames: ['Old'], unique_surnames: ['Name'])

    described_class.process(1)

    summary.reload
    expect(summary.unique_forenames).to eq(['Alice'])
    expect(summary.unique_surnames).to eq(['Smith'])
  end

  it 'removes duplicate summaries when a processed register has no names' do
    register = create_processed_register({})
    2.times { RegisterUniqueName.create!(register_id: register.id, unique_forenames: ['Old'], unique_surnames: ['Name']) }

    described_class.process(1)

    expect(RegisterUniqueName.where(register_id: register.id)).to be_empty
  end

  it 'does not leave an empty summary for a nonempty hash with no recognised names' do
    register = create_processed_register('Unrecognised Name' => ['Value'])
    RegisterUniqueName.create!(register_id: register.id, unique_forenames: ['Old'], unique_surnames: ['Name'])

    described_class.process(1)

    expect(RegisterUniqueName.where(register_id: register.id)).to be_empty
  end

  it 'removes orphan summaries after a full rebuild and preserves summaries with a parent' do
    register = create_unprocessed_register
    valid_summary = RegisterUniqueName.create!(register_id: register.id, unique_forenames: ['Jane'], unique_surnames: [])
    orphan_id = BSON::ObjectId.new
    RegisterUniqueName.collection.insert_one(_id: orphan_id, register_id: BSON::ObjectId.new, unique_forenames: ['Old'], unique_surnames: [])

    described_class.process(0)

    expect(RegisterUniqueName.where(id: valid_summary.id)).to exist
    expect(RegisterUniqueName.where(id: orphan_id)).not_to exist
  end

  it 'does not remove orphan summaries when a full rebuild traversal fails' do
    create_processed_register("Person's Forename" => ['Jane'])
    orphan_id = BSON::ObjectId.new
    RegisterUniqueName.collection.insert_one(_id: orphan_id, register_id: BSON::ObjectId.new, unique_forenames: ['Old'], unique_surnames: [])
    allow_any_instance_of(Freereg1CsvFile).to receive(:get_unique_names).and_raise('extraction failed')

    expect { described_class.process(0) }.to raise_error('extraction failed')

    expect(RegisterUniqueName.where(id: orphan_id)).to exist
  end

  it 'does not globally remove orphan summaries during a partial rebuild' do
    create_processed_register("Person's Forename" => ['Jane'])
    orphan_id = BSON::ObjectId.new
    RegisterUniqueName.collection.insert_one(_id: orphan_id, register_id: BSON::ObjectId.new, unique_forenames: ['Old'], unique_surnames: [])

    described_class.process(1)

    expect(RegisterUniqueName.where(id: orphan_id)).to exist
  end

  it 'can remove the zero-name summary it processes during a partial rebuild' do
    register = create_processed_register({})
    summary = RegisterUniqueName.create!(register_id: register.id, unique_forenames: ['Old'], unique_surnames: [])

    described_class.process(1)

    expect(RegisterUniqueName.where(id: summary.id)).not_to exist
  end
end
