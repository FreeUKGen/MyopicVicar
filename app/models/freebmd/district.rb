class District < FreebmdDbBase
  self.table_name = 'Districts'
  has_many :DistrictToCounty, foreign_key: :DistrictNumber
  has_many :records, foreign_key: :DistrictNumber, class_name: '::BestGuess'
  scope :not_invented, -> { where(Invented: 0) }

  def letterize(names)
    new_list = {}
    remainder = names
    ("A".."Z").each do |letter|
      new_list[letter] = select_elements_starting_with(names, letter)
      remainder -= new_list[letter]
    end
    [new_list, remainder]
  end

  def select_elements_starting_with(arr, letter)
    arr.select { |str| str.start_with?(letter) }
  end
end