require 'record_type'
module SamplePeople
  
  def self.primary_name(person)
    person[:transcript_names].find{ |n| n[:type] == 'primary' }
  end
  
  def self.other_name(person)
    person[:transcript_names].find{ |n| n[:type] != 'primary' }
  end
  
  
  THOMAS_RAGSDALE = { 
    :record_type => RecordType::BURIAL,
    :first_name => 'Thomas',
    :last_name => 'Ragsdale',
    :surname_inferred => true,
    :father_first_name => 'Thomas',
    :father_last_name => 'Ragsdale',
    :father_surname_inferred => false,
    :mother_first_name => 'Mary',
    :mother_last_name => 'Ragsdale',
    :mother_surname_inferred => false,
    :date => Time.new(1756, 6, 19),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  WILLIAM_FRANKLIN = {
    :record_type => RecordType::BURIAL,
    :first_name => 'William',
    :last_name => 'Franklin',
    :surname_inferred => false,
    :date => Time.new(1756,2, 3),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  ALICE_TENNANT = {
    :record_type => RecordType::BURIAL,
    :first_name => 'Alice',
    :last_name => 'Tennant',
    :surname_inferred => false,
    :husband_first_name => 'John',
    :husband_last_name => 'Tennant',
    :husband_surname_inferred => false,
    :date => Time.new(1756, 4, 21),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  SAMUEL_RAMBLE = {
    :record_type => RecordType::BURIAL,
    :first_name => 'Samuel',
    :last_name => 'Ramble',
    :surname_inferred => true,
    :mother_first_name => 'Sarah',
    :mother_last_name => 'Ramble',
    :mother_surname_inferred => false,
    :date => Time.new(1756, 11, 2),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  BARTHOLEMEW_WILTON = { 
    :record_type => RecordType::BURIAL,
    :first_name => 'Bartholemew',
    :last_name => 'Wilton',
    :surname_inferred => true,
    :father_first_name => 'Thomas',
    :father_last_name => 'Wilton',
    :father_surname_inferred => false,
    :date => Time.new(1752, 1, 7),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  ELISABETH_MORLEY = { 
    :record_type => RecordType::BAPTISM,
    :first_name => 'Elisabeth',
    :last_name => 'Morley',
    :surname_inferred => false,
    :father_first_name => 'William',
    :father_last_name => 'Morley',
    :father_surname_inferred => false,
    :mother_first_name => 'Mary',
    :mother_last_name => 'Morley',
    :mother_surname_inferred => false,
    :date => Time.new(1753, 1, 23),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  ELISABETH_ATKINS = { 
    :record_type => RecordType::BAPTISM,
    :first_name => 'Elisabeth',
    :last_name => 'Atkins',
    :surname_inferred => false,
    :father_first_name => 'Robert',
    :father_last_name => 'Atkins',
    :father_surname_inferred => false,
    :mother_first_name => 'Elisabeth',
    :mother_last_name => 'Atkins',
    :mother_surname_inferred => false,
    :date => Time.new(1753, 1, 23),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  JOHN_THORP = { 
    :record_type => RecordType::BAPTISM,
    :first_name => 'John',
    :last_name => 'Thorp',
    :surname_inferred => false,
    :father_first_name => 'John',
    :father_last_name => 'Thorp',
    :father_surname_inferred => false,
    :mother_first_name => 'Eliz.a',
    :mother_last_name => 'Thorp',
    :mother_surname_inferred => true,
    :date => Time.new(1758, 3, 5),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  JAMES_BAXTER = { 
    :record_type => RecordType::BAPTISM,
    :first_name => 'James',
    :last_name => 'Baxter',
    :surname_inferred => false,
    :father_first_name => 'Thos',
    :father_last_name => 'Baxter',
    :father_surname_inferred => false,
    :mother_first_name => 'Mary',
    :mother_last_name => 'Baxter',
    :mother_surname_inferred => true,
    :date => Time.new(1758, 4, 16),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  SUSANNA_JENNINGS = { 
    :record_type => RecordType::BAPTISM,
    :first_name => 'Susanna',
    :last_name => 'Jennings',
    :surname_inferred => false,
    :father_first_name => 'Robt',
    :father_last_name => 'Jennings',
    :father_surname_inferred => false,
    :mother_first_name => 'Eliz',
    :mother_last_name => 'Jennings',
    :mother_surname_inferred => true,
    :date => Time.new(1758, 11, 6),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  SARAH_CHALLANS = { 
    :record_type => RecordType::BAPTISM,
    :transcript_date=>"31 May 1758",
    :first_name => 'Sarah',
    :last_name => 'Challans',
    :transcript_names=>
      [{:role=>"ba",
        :type=>"primary",
        :first_name=>"Sarah",
        :last_name=>"Challans"},
       { :role=>"mr", 
         :type=>"other", 
         :first_name=>"Wm", 
         :last_name=>"Challans"}
       ],
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  
  FROM_DB = {
    :record_type=>"bu",
    :transcript_date=>"6 Mar 1690/1",
    :chapman_code=>"NFK",
    :father_first_name=>"John",
    :file_line_number=>1,
    :line_id=>"kirknorfolk.NFKALEBU.CSV.1",
    :place => "Aldeby",
    :transcript_names=>
      [{:role=>"bu",
        :type=>"primary",
        :first_name=>"Will",
        :last_name=>"SADD"},
       { :role=>"mr", 
         :type=>"other", 
         :first_name=>"John", 
         :last_name=>"SADD"}
       ]
 }

  RICHARD_AND_ESTHER = { 
    :record_type => RecordType::MARRIAGE,
    :transcript_date=>"* * 1753",
    :chapman_code=>"LIN",
    :transcript_names=>
   [
      { :role => NameRole::GROOM,
        :type => 'primary',
        :first_name => 'Richard',
        :last_name => 'Bell'
      },
      {
        :role => NameRole::BRIDE,
        :type => 'primary',
        :first_name => 'Esther',
        :last_name => 'Brackenbury'
      }     
    ], 
    :parish => 'Bicker'
 }
  
  
  MICHAEL_AND_MARY = { 
    :record_type => RecordType::MARRIAGE,
    :groom_first_name => 'Michael',
    :groom_last_name => 'Tubbs',
    :groom_surname_inferred => false,
    :bride_first_name => 'Mary',
    :bride_last_name => 'Howesley',
    :bride_surname_inferred => false,
    :date => Time.new(1753, 3, 5),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }
  
  BURIALS_AND_BAPTISMS = 
    [THOMAS_RAGSDALE,
     WILLIAM_FRANKLIN,
     ALICE_TENNANT,
     SAMUEL_RAMBLE,
     BARTHOLEMEW_WILTON,
     ELISABETH_MORLEY,
     ELISABETH_ATKINS]
     
  MARRIAGES = [RICHARD_AND_ESTHER,MICHAEL_AND_MARY]

end