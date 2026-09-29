require 'spec_helper'

describe Register, '#destroy' do
  def clean_register_records
    RegisterUniqueName.delete_all
    Source.delete_all
    Freereg1CsvFile.delete_all
    Register.delete_all
    Church.delete_all
    Place.delete_all
  end

  before(:each) { clean_register_records }
  after(:each) { clean_register_records }

  def create_register
    place = Place.create!(place_name: 'Test Place', chapman_code: 'CHI', latitude: 51, longitude: 0)
    church = Church.create!(church_name: 'Test Church', place_id: place.id)
    Register.create!(church_id: church.id)
  end

  it 'destroys all derived unique-name summaries, including legacy duplicates' do
    register = create_register
    2.times { RegisterUniqueName.create!(register_id: register.id, unique_forenames: [], unique_surnames: []) }

    expect(register.destroy).to be_truthy
    expect(RegisterUniqueName.where(register_id: register.id)).to be_empty
  end

  it 'retains the register and its summary when a file restriction applies' do
    register = create_register
    summary = RegisterUniqueName.create!(register_id: register.id, unique_forenames: ['Jane'], unique_surnames: [])
    Freereg1CsvFile.collection.insert_one(_id: BSON::ObjectId.new, register_id: register.id)

    expect(register.destroy).to be_falsey
    expect(Register.where(id: register.id)).to exist
    expect(RegisterUniqueName.where(id: summary.id)).to exist
  end

  it 'retains the register and its summary when a source restriction applies' do
    register = create_register
    summary = RegisterUniqueName.create!(register_id: register.id, unique_forenames: ['Jane'], unique_surnames: [])
    Source.collection.insert_one(_id: BSON::ObjectId.new, register_id: register.id)

    expect(register.destroy).to be_falsey
    expect(Register.where(id: register.id)).to exist
    expect(RegisterUniqueName.where(id: summary.id)).to exist
  end
end
