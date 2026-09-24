require 'spec_helper'

describe Register, '#merge_registers' do
  def transaction_capable?
    Mongoid::Clients.default.database.command(hello: 1).first['setName'].present?
  end

  def insert(model, attributes)
    id = BSON::ObjectId.new
    document = { _id: id }.merge(attributes)
    if model == EmbargoRule
      timestamp = Time.now.utc
      document[:created_at] ||= timestamp
      document[:updated_at] ||= timestamp
    end
    model.collection.insert_one(document)
    id
  end

  def build_registers
    place_id = insert(Place, place_name: 'Merge Place', chapman_code: 'MER')
    church_id = insert(Church, place_id: place_id, church_name: 'Merge Church')
    target_id = insert(Register, church_id: church_id, register_type: 'BA')
    losing_id = insert(Register, church_id: church_id, register_type: 'BA')
    [Register.find(target_id), Register.find(losing_id)]
  end

  def require_transactions
    skip 'test MongoDB is standalone; a replica set is required for transaction integration coverage' unless transaction_capable?
  end

  before do
    [SearchRecord, Freereg1CsvEntry, ImageServerImage, ImageServerGroup, Source, Gap, EmbargoRule,
     RegisterUniqueName, Freereg1CsvFile, Register, Church, Place].each(&:delete_all)
  end

  after do
    [SearchRecord, Freereg1CsvEntry, ImageServerImage, ImageServerGroup, Source, Gap, EmbargoRule,
     RegisterUniqueName, Freereg1CsvFile, Register, Church, Place].each(&:delete_all)
  end

  it 'rejects input on any losing register without mutating anything' do
    target, losing = build_registers
    losing.set(register_notes: 'do not merge')
    file_id = insert(Freereg1CsvFile, register_id: losing.id, file_name: 'losing.csv')
    source_id = insert(Source, register_id: losing.id, source_name: 'Image Server')

    result = target.merge_registers

    expect(result).to eq([false, 'a register being merged has input'])
    expect(Freereg1CsvFile.find(file_id).register_id).to eq(losing.id)
    expect(Source.find(source_id).register_id).to eq(losing.id)
    expect(Register.where(id: losing.id)).to exist
  end

  it 'fails clearly without mutating when MongoDB does not support transactions' do
    skip 'deployment supports transactions' if transaction_capable?
    target, losing = build_registers
    file_id = insert(Freereg1CsvFile, register_id: losing.id, file_name: 'losing.csv')

    proceed, message = target.merge_registers

    expect(proceed).to be false
    expect(message).to match(/Transaction numbers are only allowed|transaction/i)
    expect(Freereg1CsvFile.find(file_id).register_id).to eq(losing.id)
    expect(Register.where(id: losing.id)).to exist
  end

  context 'with transaction-capable MongoDB' do
    before { require_transactions }

    it 'transfers every dependency, preserves image relationships, deduplicates embargoes, and destroys the loser' do
      target, losing = build_registers
      target_file_id = insert(Freereg1CsvFile, register_id: target.id, file_name: 'target.csv', record_type: 'ba')
      losing_file_id = insert(Freereg1CsvFile, register_id: losing.id, file_name: 'losing.csv', record_type: 'ba')
      insert(Freereg1CsvEntry, freereg1_csv_file_id: target_file_id, person_forename: 'Target', person_surname: 'Name')
      entry_id = insert(
        Freereg1CsvEntry,
        freereg1_csv_file_id: losing_file_id,
        record_type: 'BA',
        person_forename: 'Losing',
        person_surname: 'Person',
        embargo_records: []
      )
      search_id = insert(SearchRecord, freereg1_csv_entry_id: entry_id, embargoed: true, release_year: Date.current.year + 10)

      target_source_id = insert(Source, register_id: target.id, source_name: 'Image Server')
      losing_source_id = insert(Source, register_id: losing.id, source_name: 'Image Server')
      group_id = insert(ImageServerGroup, source_id: losing_source_id, group_name: 'group')
      image_id = insert(ImageServerImage, image_server_group_id: group_id)
      gap_id = insert(Gap, register_id: losing.id, start_date: 1900, end_date: 1901, record_type: 'BA')

      target_rule_id = insert(
        EmbargoRule,
        register_id: target.id,
        period: 100,
        period_type: 'period',
        rule: 'Embargoed for the period of ',
        record_type: 'BA',
        reason: 'target'
      )
      losing_rule_id = insert(
        EmbargoRule,
        register_id: losing.id,
        period: 100,
        period_type: 'period',
        rule: 'Embargoed for the period of ',
        record_type: 'BA',
        reason: 'losing'
      )
      unique_rule_id = insert(
        EmbargoRule,
        register_id: losing.id,
        period: 80,
        period_type: 'period',
        rule: 'Embargoed for the period of ',
        record_type: 'BU',
        reason: 'unique'
      )
      Freereg1CsvEntry.where(id: entry_id).update_all(
        embargo_records: [{
          _id: BSON::ObjectId.new,
          embargoed: true,
          who: 'register_rule',
          why: 'losing',
          rule_applied: losing_rule_id.to_s,
          rule_date: Time.now.utc.to_s,
          release_year: Date.current.year + 10,
          release_date: Date.current.year + 10
        }]
      )
      2.times { insert(RegisterUniqueName, register_id: target.id, unique_forenames: ['Stale'], unique_surnames: []) }
      2.times { insert(RegisterUniqueName, register_id: losing.id, unique_forenames: ['Old'], unique_surnames: []) }

      expect(FileUtils).not_to receive(:mv)
      expect(FileUtils).not_to receive(:move)
      expect(File).not_to receive(:rename)

      proceed, message = target.merge_registers

      expect([proceed, message]).to eq([true, ''])
      expect(Register.where(id: target.id)).to exist
      expect(Register.where(id: losing.id)).not_to exist
      expect(Register.where(church_id: nil, register_type: 'BA')).not_to exist
      expect(Freereg1CsvFile.where(:id.in => [target_file_id, losing_file_id]).distinct(:register_id)).to eq([target.id])
      expect(Source.where(:id.in => [target_source_id, losing_source_id], register_id: target.id).count).to eq(2)
      expect(ImageServerGroup.find(group_id).source_id).to eq(losing_source_id)
      expect(ImageServerImage.find(image_id).image_server_group_id).to eq(group_id)
      expect(Gap.find(gap_id).register_id).to eq(target.id)
      expect(EmbargoRule.where(id: losing_rule_id)).not_to exist
      expect(EmbargoRule.find(target_rule_id).register_id).to eq(target.id)
      expect(EmbargoRule.find(unique_rule_id).register_id).to eq(target.id)

      entry = Freereg1CsvEntry.find(entry_id)
      expect(entry.embargo_records.last.rule_applied).to eq(target_rule_id.to_s)
      expect(entry.embargo_records.last.rule_date).to eq(EmbargoRule.find(target_rule_id).updated_at.utc.to_s)
      expect(entry.currently_under_embargo?).to be true
      expect(SearchRecord.find(search_id).embargoed).to be true

      summaries = RegisterUniqueName.where(register_id: target.id).to_a
      expect(summaries.length).to eq(1)
      expect(summaries.first.unique_forenames).to contain_exactly('Losing', 'Target')
      expect(summaries.first.unique_surnames).to contain_exactly('Name', 'Person')
      expect(RegisterUniqueName.where(register_id: losing.id)).not_to exist
      expect(Freereg1CsvFile.where(register_id: losing.id)).not_to exist
      expect(Source.where(register_id: losing.id)).not_to exist
      expect(Gap.where(register_id: losing.id)).not_to exist
      expect(EmbargoRule.where(register_id: losing.id)).not_to exist
    end

    it 'rolls back all writes when a mid-merge operation fails' do
      target, losing = build_registers
      file_id = insert(Freereg1CsvFile, register_id: losing.id, file_name: 'losing.csv')
      allow(target).to receive(:merge_embargo_rules!) do
        expect(Freereg1CsvFile.find(file_id).register_id).to eq(target.id)
        raise 'injected failure'
      end

      proceed, message = target.merge_registers

      expect(proceed).to be false
      expect(message).to include('injected failure')
      expect(Freereg1CsvFile.find(file_id).register_id).to eq(losing.id)
      expect(Register.where(id: losing.id)).to exist
    end

    it 'rolls back when destruction returns false' do
      target, losing = build_registers
      file_id = insert(Freereg1CsvFile, register_id: losing.id, file_name: 'losing.csv')
      source_id = insert(Source, register_id: losing.id, source_name: 'Image Server')
      gap_id = insert(Gap, register_id: losing.id, start_date: 1900, end_date: 1901, record_type: 'BA')
      rule_id = insert(
        EmbargoRule,
        register_id: losing.id,
        period: 80,
        period_type: 'period',
        rule: 'Embargoed for the period of ',
        record_type: 'BU',
        reason: 'losing'
      )
      summary_id = insert(RegisterUniqueName, register_id: losing.id, unique_forenames: ['Old'], unique_surnames: [])
      expect_any_instance_of(Register).to receive(:destroy) do |register|
        expect(register.id).to eq(losing.id)
        expect(Freereg1CsvFile.find(file_id).register_id).to eq(target.id)
        expect(Source.find(source_id).register_id).to eq(target.id)
        expect(Gap.find(gap_id).register_id).to eq(target.id)
        expect(EmbargoRule.find(rule_id).register_id).to eq(target.id)
        expect(RegisterUniqueName.where(id: summary_id)).not_to exist
        false
      end

      proceed, message = target.merge_registers

      expect(proceed).to be false
      expect(message).to include('failed to destroy losing register')
      expect(Freereg1CsvFile.find(file_id).register_id).to eq(losing.id)
      expect(Source.find(source_id).register_id).to eq(losing.id)
      expect(Gap.find(gap_id).register_id).to eq(losing.id)
      expect(EmbargoRule.find(rule_id).register_id).to eq(losing.id)
      expect(RegisterUniqueName.where(id: summary_id)).to exist
      expect(RegisterUniqueName.where(register_id: target.id)).not_to exist
      expect(Register.where(id: losing.id)).to exist
    end
  end
end
