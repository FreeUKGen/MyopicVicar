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

  def self.model_label(model_name)
    DEPENDENCY_LABELS[model_name.to_s] || model_name.to_s
  end

  def initialize(target_register)
    @target = target_register
  end

  # Read-only summary for coordinator UI (Phase 2 Step B).
  def preview
    return preview_error('Target register is missing') if @target.blank?

    merge_candidates = merge_candidate_registers
    register_type_label = RegisterType.display_name(@target.register_type)

    if merge_candidates.blank?
      return {
        error: nil,
        merge_allowed: false,
        no_candidates: true,
        register_type_label: register_type_label,
        target_id: @target.id,
        candidates: [],
        totals: empty_dependency_totals,
        blockers: [],
        message: 'No other registers with this type exist for this church.'
      }
    end

    candidates = merge_candidates.map { |src| candidate_preview_row(src) }
    totals = sum_dependency_totals(candidates)
    blockers = candidates.select { |c| c[:blocked] }

    {
      error: nil,
      merge_allowed: blockers.empty?,
      no_candidates: false,
      register_type_label: register_type_label,
      target_id: @target.id,
      candidates: candidates,
      totals: totals,
      blockers: blockers,
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
      error: message,
      merge_allowed: false,
      no_candidates: false,
      register_type_label: nil,
      target_id: nil,
      candidates: [],
      totals: empty_dependency_totals,
      blockers: [],
      message: message
    }
  end

  def candidate_preview_row(source)
    counts = dependency_counts_for(source.id)
    blocked = source.has_input?
    {
      id: source.id,
      dependency_counts: counts,
      blocked: blocked,
      block_reason: blocked ? 'Has coordinator-entered metadata (status, quality, source, copyright, notes, or year range).' : nil
    }
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
    detail = totals_moved.filter_map do |name, n|
      "#{self.class.model_label(name)}: #{n}" if n.positive?
    end
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
  rescue Mongo::Error::OperationFailure => e
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
