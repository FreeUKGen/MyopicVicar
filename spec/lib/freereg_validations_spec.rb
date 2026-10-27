# frozen_string_literal: true

require_relative '../../lib/freereg_validations'

RSpec.describe FreeregValidations do
  describe '.valid_ucf_expression?' do
    it 'accepts well-formed UCF name and date expressions' do
      expect(described_class.valid_ucf_expression?('AM?S')).to be(true)
      expect(described_class.valid_ucf_expression?('SM_TH')).to be(true)
      expect(described_class.valid_ucf_expression?('SM[TH]ITH')).to be(true)
      expect(described_class.valid_ucf_expression?('17_{1,2} Jan 1870')).to be(true)
      expect(described_class.valid_ucf_expression?('1*_Jan_1870')).to be(true)
    end

    it 'rejects malformed UCF expressions' do
      invalid_values = [
        '[I_[N*',
        '?[',
        'D[AU_[NN',
        'SITCHELL (REGISTER NOTES (OR SEARCHEL}',
        'HEAL(SY}',
        '[H_[ISSUM?',
        'AMOS[]',
        'AM_{}S',
        'AM(   )S',
        'SM[123]ITH',
        '{1,2}GATE',
        'SM_{a,3}TH'
      ]

      invalid_values.each do |value|
        expect(described_class.valid_ucf_expression?(value)).to be(false), "Expected #{value.inspect} to be invalid"
      end
    end
  end
end
