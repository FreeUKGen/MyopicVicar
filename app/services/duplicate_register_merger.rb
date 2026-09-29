# frozen_string_literal: true

require 'csv'

# Finds registers that duplicate another register at the same church (same register_type) and
# merges each group into one register with RegisterMergeService. Writes a CSV report either way.
#
# Which register is kept:
#   1. the register with an Image Server source (Image Server folders are not combined automatically)
#   2. otherwise the register with coordinator-entered fields (RegisterMergeService won't merge those away)
#   3. otherwise the only register with dependencies
#   4. otherwise the register with the most records; the oldest on a tie or when none has dependencies
#
# A group is left for manual review when more than one register has an Image Server source or
# coordinator-entered fields, when those are on different registers, or when embargo rules for
# the same record type have different periods.
class DuplicateRegisterMerger
  REPORT_HEADERS = %w[chapman_code place church register_type decision keep_register_id delete_register_ids reason result].freeze

  def initialize(apply: false, chapman_code: nil, limit: 0)
    @apply = apply
    @chapman_code = chapman_code
    @limit = limit.to_i
  end

  # Returns the path of the CSV report.
  def run
    report_path = Rails.root.join('log', "merge_duplicate_registers_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv")
    processed = 0
    CSV.open(report_path, 'w') do |csv|
      csv << REPORT_HEADERS
      duplicate_groups.each do |registers|
        church = registers.first.church
        place = church&.place
        next if place.blank?
        next if @chapman_code.present? && place.chapman_code != @chapman_code

        plan = plan_for(registers)
        result = @apply && plan[:decision] == 'merge' ? merge(plan[:keep]) : ''
        csv << [place.chapman_code, place.place_name, church.church_name, registers.first.register_type,
                plan[:decision], plan[:keep]&.id, plan[:delete].map(&:id).join(' '), plan[:reason], result]
        processed += 1
        break if @limit.positive? && processed >= @limit
      end
    end
    report_path
  end

  # registers: one duplicate group, oldest first.
  def plan_for(registers)
    image_registers = registers.select(&:image_servers_exist?)
    return manual('more than one register has an Image Server source') if image_registers.size > 1

    input_registers = registers.select(&:has_input?)
    return manual('more than one register has coordinator-entered fields') if input_registers.size > 1
    if image_registers.any? && input_registers.any? && image_registers != input_registers
      return manual('Image Server source and coordinator-entered fields are on different registers')
    end

    conflict = embargo_period_conflict(registers)
    return manual(conflict) if conflict

    keep, reason = choose_register_to_keep(registers, image_registers, input_registers)
    { decision: 'merge', keep: keep, delete: registers - [keep], reason: reason }
  end

  private

  def duplicate_groups
    # Collect ids up front so a long run of merges doesn't hold an aggregation cursor open.
    groups = Register.collection.aggregate([
      { '$match' => { church_id: { '$ne' => nil } } },
      { '$group' => { _id: { church_id: '$church_id', register_type: '$register_type' }, ids: { '$push' => '$_id' } } },
      { '$match' => { 'ids.1' => { '$exists' => true } } }
    ]).map { |group| group['ids'] }

    Enumerator.new do |yielder|
      groups.each do |ids|
        registers = Register.where(:id.in => ids).order_by(c_at: 1, _id: 1).to_a
        yielder << registers if registers.size > 1
      end
    end
  end

  def choose_register_to_keep(registers, image_registers, input_registers)
    return [image_registers.first, 'kept the register with an Image Server source'] if image_registers.any?
    return [input_registers.first, 'kept the register with coordinator-entered fields'] if input_registers.any?

    with_dependencies = registers.select { |register| dependencies?(register) }
    case with_dependencies.size
    when 0
      [registers.first, 'no register has dependencies; kept the oldest']
    when 1
      [with_dependencies.first, 'kept the only register with dependencies']
    else
      # max_by returns the first of equal maxima, and registers are oldest first.
      [with_dependencies.max_by { |register| record_count(register) }, 'kept the register with the most records']
    end
  end

  def dependencies?(register)
    RegisterMergeService::DEPENDENCY_MODELS.any? { |model| model.where(register_id: register.id).exists? }
  end

  def record_count(register)
    Freereg1CsvFile.where(register_id: register.id).pluck(:records).sum(&:to_i)
  end

  # RegisterMergeService only combines embargo rules whose periods match; different periods for
  # the same rule and record type need a person to decide which one applies.
  def embargo_period_conflict(registers)
    rules = EmbargoRule.where(:register_id.in => registers.map(&:id)).to_a
    conflicting = rules.group_by { |rule| [rule.rule, rule.record_type] }.select { |_key, group| group.map(&:period).uniq.size > 1 }
    return if conflicting.empty?

    "embargo rules with different periods for record type(s) #{conflicting.keys.map(&:last).uniq.join(', ')}"
  end

  def merge(keep)
    proceed, message = RegisterMergeService.new(keep).call
    return "failed: #{message}" unless proceed

    keep.reload.calculate_register_numbers
    sleep(Rails.application.config.sleep.to_f)
    "merged: #{message}"
  end

  def manual(reason)
    { decision: 'manual', keep: nil, delete: [], reason: reason }
  end
end
