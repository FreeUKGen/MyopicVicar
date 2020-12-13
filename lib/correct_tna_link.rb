class CorrectTnaLink

  def self.process(len)
    limit = len.to_i
    number = 0
    corrected = 0
    Freecen2District.where(year: '1841').order_by(name: 1).each do |district|
      number += 1
      break if number >= limit

      tna_parts = district.tnaid.split('.')
      next if tna_parts.length == 1

      district.update_attributes(tnaid: tna_parts[0])

      corrected += 1
    end

    p "Processed #{number} districts and corrected #{corrected}"
  end
end
