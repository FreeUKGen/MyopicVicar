class HashSanitizer

	def initialize(hash)
    @hash = hash
  end

  def sanitize_keys
    sanitize_hash.keys if sanitize_hash.present?
  end

  def sanitize_values
    sanitize_hash.values if sanitize_hash.present?
  end

  private

  def sanitize_hash
    @hash.compact
  end

end