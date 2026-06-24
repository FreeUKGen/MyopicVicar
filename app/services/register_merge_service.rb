# frozen_string_literal: true

class RegisterMergeService
  DEPENDENCY_MODELS = [
    Source,
    Freereg1CsvFile,
    EmbargoRule,
    Gap,
    RegisterUniqueName
  ].freeze

  DEPENDENCY_LABELS = {
    'Source' => 'Sources (incl. image server)',
    'Freereg1CsvFile' => 'Batches (CSV files)',
    'EmbargoRule' => 'Embargo rules',
    'Gap' => 'Gaps',
    'RegisterUniqueName' => 'Unique name lists'
  }.freeze

  # Max rows listed per dependency type on the dry-run page (counts always show full totals).
  PREVIEW_ITEM_LIMIT = 25

  COORDINATOR_METADATA_FIELDS = {
    status: 'Status',
    quality: 'Quality',
    source: 'Source',
    copyright: 'Copyright',
    register_notes: 'Register notes',
    minimum_year_for_register: 'Minimum year',
    maximum_year_for_register: 'Maximum year'
  }.freeze

  def self.model_label(model_name)
    DEPENDENCY_LABELS[model_name.to_s] || model_name.to_s
  end

  def initialize(target_register)
    @target = target_register
  end

  # Read-only dry run for coordinator UI: no database writes.
  def preview
    dry_run
  end

  def dry_run
    return preview_error('Target register is missing') if @target.blank?

    merge_candidates = merge_candidate_registers
    register_type_label = RegisterType.display_name(@target.register_type)

    if merge_candidates.blank?
      return {
        dry_run: true,
        error: nil,
        merge_allowed: false,
        no_candidates: true,
        register_type_label: register_type_label,
        target_id: @target.id,
        target: target_dry_run_summary(register_type_label),
        candidates: [],
        totals: empty_dependency_totals,
        blockers: [],
        planned_actions: empty_planned_actions,
        message: 'No other registers with this type exist for this church.'
      }
    end

    candidates = merge_candidates.map { |src| candidate_dry_run_row(src) }
    totals = sum_dependency_totals(candidates)
    blockers = candidates.select { |c| c[:blocked] }

    {
      dry_run: true,
      error: nil,
      merge_allowed: blockers.empty?,
      no_candidates: false,
      register_type_label: register_type_label,
      target_id: @target.id,
      target: target_dry_run_summary(register_type_label),
      candidates: candidates,
      totals: totals,
      blockers: blockers,
      planned_actions: build_planned_actions(candidates, totals),
      message: nil
    }
  end

  def call
    return failure('Target register is missing') if @target.blank?

    merge_candidates = merge_candidate_registers
    if merge_candidates.blank?
      return success('No other registers with this type exist for this church. Nothing to merge.')
    end

    blockers = merge_candidates.select(&:has_input?)
    if blockers.any?
      ids = blockers.map { |r| r.id.to_s }.join(', ')
      return failure(
        "Cannot merge: #{blockers.size} duplicate register(s) have coordinator-entered metadata " \
        '(status, quality, source, copyright, notes, or min/max year). ' \
        "Register id(s): #{ids}. Edit those registers first or clear the extra fields."
      )
    end

    totals_moved = empty_dependency_totals
    merged_ids = []

    with_merge_transaction do
      merge_candidates.each do |source|
        DEPENDENCY_MODELS.each do |model|
          totals_moved[model.name] += model.where(register_id: source.id).count
        end
        merged_ids << source.id
        merge_one!(source)
      end
    end

    success(build_success_summary(merged_ids, totals_moved))
  rescue StandardError => e
    Rails.logger.error("FREEREG:REGISTER_MERGE: Failed for #{@target.id}: #{e.class} #{e.message}")
    failure("Merge failed: #{e.message}")
  end

  private

  def merge_candidate_registers
    @target.church.registers.where(:id.ne => @target.id, register_type: @target.register_type)
  end

  def preview_error(message)
    {
      dry_run: true,
      error: message,
      merge_allowed: false,
      no_candidates: false,
      register_type_label: nil,
      target_id: nil,
      target: nil,
      candidates: [],
      totals: empty_dependency_totals,
      blockers: [],
      planned_actions: empty_planned_actions,
      message: message
    }
  end

  def target_dry_run_summary(register_type_label)
    {
      id: @target.id,
      register_type: @target.register_type,
      register_type_label: register_type_label,
      alternate_register_name: @target.alternate_register_name,
      dependency_counts: dependency_counts_for(@target.id),
      csv_entry_count: csv_entry_count_for_register(@target.id),
      coordinator_fields: coordinator_metadata_fields(@target)
    }
  end

  def candidate_preview_row(source)
    counts = dependency_counts_for(source.id)
    blocked = source.has_input?
    {
      id: source.id,
      dependency_counts: counts,
      blocked: blocked,
      block_reason: blocked ? coordinator_metadata_block_reason(source) : nil
    }
  end

  def candidate_dry_run_row(source)
    candidate_preview_row(source).merge(
      alternate_register_name: source.alternate_register_name,
      register_name: source.register_name,
      csv_entry_count: csv_entry_count_for_register(source.id),
      coordinator_fields: coordinator_metadata_fields(source),
      affected: affected_items_by_dependency(source.id)
    )
  end

  def build_planned_actions(candidates, totals)
    {
      registers_to_delete: candidates.map { |c| c[:id] },
      registers_to_delete_count: candidates.size,
      items_reassigned: totals,
      csv_entries_reassigned: candidates.sum { |c| c[:csv_entry_count].to_i },
      notes: [
        'No transcription rows (CSV entries) or search records are deleted; batches are reassigned to the target register.',
        'Duplicate Register documents listed below will be permanently deleted after a successful merge.'
      ]
    }
  end

  def empty_planned_actions
    {
      registers_to_delete: [],
      registers_to_delete_count: 0,
      items_reassigned: empty_dependency_totals,
      csv_entries_reassigned: 0,
      notes: []
    }
  end

  def coordinator_metadata_fields(register)
    COORDINATOR_METADATA_FIELDS.map do |field, label|
      value = register.public_send(field)
      next if value.blank?

      { field: field.to_s, label: label, value: value.to_s.truncate(120) }
    end.compact
  end

  def coordinator_metadata_block_reason(register)
    labels = coordinator_metadata_fields(register).map { |f| f[:label] }
    "Has coordinator metadata: #{labels.join(', ')}."
  end

  def affected_items_by_dependency(register_id)
    DEPENDENCY_MODELS.each_with_object({}) do |model, h|
      h[model.name] = list_affected_items(model, register_id)
    end
  end

  def list_affected_items(model, register_id)
    scope = model.where(register_id: register_id)
    total = scope.count
    rows = scope.limit(PREVIEW_ITEM_LIMIT + 1).to_a
    truncated = rows.size > PREVIEW_ITEM_LIMIT
    rows = rows.first(PREVIEW_ITEM_LIMIT) if truncated

    {
      total: total,
      truncated: truncated,
      items: rows.map { |record| affected_item_row(model, record) }
    }
  end

  def affected_item_row(model, record)
    case model.name
    when 'Freereg1CsvFile'
      {
        id: record.id,
        label: "#{record.userid} / #{record.file_name}",
        detail: "#{record.records} records, type #{record.record_type}"
      }
    when 'Source'
      {
        id: record.id,
        label: record.source_name.presence || '(unnamed source)',
        detail: record.url.present? ? record.url.truncate(80) : nil
      }
    when 'EmbargoRule'
      {
        id: record.id,
        label: "#{record.rule} (#{record.record_type})",
        detail: record.reason
      }
    when 'Gap'
      {
        id: record.id,
        label: "#{record.start_date}–#{record.end_date} (#{record.record_type})",
        detail: record.reason
      }
    when 'RegisterUniqueName'
      surnames = record.unique_surnames&.size.to_i
      forenames = record.unique_forenames&.size.to_i
      {
        id: record.id,
        label: 'Unique name list',
        detail: "#{surnames} surnames, #{forenames} forenames"
      }
    else
      { id: record.id, label: record.id.to_s, detail: nil }
    end
  end

  def csv_entry_count_for_register(register_id)
    batch_ids = Freereg1CsvFile.where(register_id: register_id).pluck(:id)
    return 0 if batch_ids.blank?

    Freereg1CsvEntry.where(:freereg1_csv_file_id.in => batch_ids).count
  end

  def dependency_counts_for(register_id)
    DEPENDENCY_MODELS.each_with_object({}) do |model, h|
      h[model.name] = model.where(register_id: register_id).count
    end
  end

  def empty_dependency_totals
    DEPENDENCY_MODELS.each_with_object({}) { |m, h| h[m.name] = 0 }
  end

  def sum_dependency_totals(candidate_rows)
    totals = empty_dependency_totals
    candidate_rows.each do |row|
      row[:dependency_counts].each { |name, n| totals[name] += n.to_i }
    end
    totals
  end

  def build_success_summary(merged_ids, totals_moved)
    parts = []
    parts << "Merged #{merged_ids.size} duplicate register(s) (ids: #{merged_ids.map(&:to_s).join(', ')}) into this register."
    detail = totals_moved.map do |name, n|
      "#{self.class.model_label(name)}: #{n}" if n.positive?
    end.compact
    parts << "Reassigned — #{detail.join('; ')}." if detail.any?
    parts.join(' ')
  end

  def merge_one!(source)
    DEPENDENCY_MODELS.each do |model|
      before_count = model.where(register_id: source.id).count
      next if before_count.zero?

      moved = model.where(register_id: source.id).update_all(register_id: @target.id)
      remaining = model.where(register_id: source.id).count
      raise "Could not move all #{model.name} records from #{source.id}" unless remaining.zero?
      raise "Unexpected moved count for #{model.name} on #{source.id}" if moved.to_i < before_count
    end

    source.destroy
    raise "Could not delete merged register #{source.id}" if Register.where(id: source.id).exists?
  end

  # Transactions are supported only on replica sets/sharded clusters.
  # If unavailable, we still run with strict verification and fail fast.
  def with_merge_transaction
    client = Mongoid::Clients.default
    return yield unless client.respond_to?(:start_session)

    client.start_session do |session|
      if session.respond_to?(:with_transaction)
        session.with_transaction do
          yield
        end
      else
        yield
      end
    end
  rescue Mongo::Error => e
    Rails.logger.warn("FREEREG:REGISTER_MERGE: transaction unavailable, fallback: #{e.message}")
    yield
  end

  def success(message)
    [true, message]
  end

  def failure(message)
    [false, message]
  end
end
