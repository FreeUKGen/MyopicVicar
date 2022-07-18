class ScanList < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'ScanList'
  belongs_to :BestGuessHash, foreign_key: 'Hash'
	ABSOLUTE=1;
	VERY_PROBABLE=2;
	PROBABLE=3;
	VERY_POSSIBLE=4;
	POSSIBLE=5;
	UNLIKELY=6;
	VERY_UNLIKELY=7;
	ABSOLUTELY_NO=8;
	DEFINITIVE = 2;

	scope :unrejected, -> { where(Rejected: 0) }
	scope :approved, -> { where("Definitive > ?", 0) }
	scope :definitive, -> { where("Confirmed >= ?", DEFINITIVE) }
	scope :probable, -> { where("Confirmed >= ?", 0) }
	scope :absolutely_not, -> { where("Definitive < ?", 0) }
	scope :rejected, -> { where("Rejected > ?", 0) }
	scope :unlikely_scans, -> { where(Definitive: 0, Confirmed: 0) }
	scope :non_definite, -> { where(Definitive: 0)}
	scope :probably_confirm, -> { where('Confirmed - Rejected >= ?', 4) }
	scope :possibly_confirm, -> { where('Confirmed - Rejected >= ?', 2) }
		scope :can_be_confirm, -> { where('Confirmed - Rejected >= ?', 0) }

end