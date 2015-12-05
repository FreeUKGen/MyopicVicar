module FormHelper
  def setup_freereg1_csv_entry(freereg1_csv_entry)
    freereg1_csv_entry.multiple_witnesses ||= MultipleWitness.new
    freereg1_csv_entry
  end
end