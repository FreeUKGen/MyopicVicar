class Postem < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'Postems'
  belongs_to :best_guess_hash, foreign_key: 'Hash', primary_key: 'Hash', class_name: '::BestGuessHash'

  MAX_INFORMATION_LENGTH = 250

  before_validation :truncate_information_to_max_length
  validates :Information, presence: true, length: { maximum: MAX_INFORMATION_LENGTH }
  validate :information_contains_space_or_newline

  # Reject duplicate content for same record (same Hash + Information) like FreeBMD1
  validate :no_duplicate_postem, on: :create

  private

  def truncate_information_to_max_length
    return if self['Information'].blank?
    self['Information'] = self['Information'].to_s[0, MAX_INFORMATION_LENGTH]
  end

  def information_contains_space_or_newline
    return if self['Information'].blank?
    return if self['Information'].to_s =~ /\s/
    errors.add(:Information, 'must contain at least one space or newline')
  end

  def no_duplicate_postem
    return if self['Hash'].blank? || self['Information'].blank?
    normalized = self['Information'].to_s.strip
    return unless Postem.where(Hash: self['Hash']).exists?(['TRIM(Information) = ?', normalized])
    errors.add(:base, 'A postem with this content already exists for this record')
  end
end