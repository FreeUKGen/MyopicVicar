task :bicker_demo => :environment do
  #Template.delete_all
  #Entity.delete_all
  #Asset.delete_all
  
  template = Template.create( :name => "Bicker GR 18th Century",
                              :description => "A template for transcribing GR images from eighteenth-century register",
                              :project => "FreeREG",
                              :display_width => 800,
                              :default_zoom => 1.5)
                          

  date = Field.new( :name => "Date",
                        :field_key=>"date",
                        :kind=>"text" )
  fn_field = Field.new( :name => "First Name",
                        :field_key=>"first_name",
                        :kind=>"text" )
  ln_field = Field.new( :name => "Surame",
                        :field_key=>"last_name",
                        :kind=>"text" )
  ln_inferred = Field.new( :name => "Inferred?", :field_key=>"ln_inferred",:kind=>"select",
                        :options => { :select => ['Y', 'N'] } )
  sex = Field.new( :name => "Sex", :field_key=>"sex",:kind=>"select",
                        :initial_value => "--",
                        :options => { :select => ['M', 'F'] } )
  p_fn_field = Field.new( :name => "Father's Name",
                        :field_key=>"father_first_name",
                        :kind=>"text" )
  p_ln_field = Field.new( :name => "Father's Surame",
                        :field_key=>"father_last_name",
                        :kind=>"text" )
  m_fn_field = Field.new( :name => "Mother's Name",
                        :field_key=>"mother_first_name",
                        :kind=>"text" )
  m_ln_field = Field.new( :name => "Mother's Surame",
                        :field_key=>"mother_last_name",
                        :kind=>"text" )
  notes_field = Field.new( :name => "Notes",
                        :field_key=>"notes",
                        :kind=>"text" )


  burial_bicker = Entity.create( :name => "Burial",
                                   	      :description => "Burial Record",
                                  	      :help => "Select Burials",
                                  	      :resizeable => true,
                                  	      :width => 450,
                                  	      :height => 80)
                                  
					    
  burial_bicker.fields << date  
  burial_bicker.fields << fn_field  
  burial_bicker.fields << ln_field   
  burial_bicker.fields << ln_inferred  
  burial_bicker.fields << p_fn_field  
  burial_bicker.fields << p_ln_field  
  burial_bicker.fields << m_fn_field  
  burial_bicker.fields << m_ln_field  
  burial_bicker.fields << notes_field  

  baptism_bicker = Entity.create( :name => "Baptism",
                                          :description => "Baptism Record",
                                          :help => "Select Baptisms",
                                          :resizeable => true,
                                          :width => 450,
                                          :height => 80)
                                  
  baptism_bicker.fields << date  
  baptism_bicker.fields << fn_field  
#  baptism_bicker.fields << ln_field   
#  baptism_bicker.fields << ln_inferred  
  baptism_bicker.fields << p_fn_field  
  baptism_bicker.fields << p_ln_field  
  baptism_bicker.fields << m_fn_field  
  baptism_bicker.fields << m_ln_field  
  baptism_bicker.fields << notes_field  

  marriage_bicker = Entity.create( :name => "Marriage",
                                          :description => "Marriage Record",
                                          :help => "Select Marriages",
                                          :resizeable => true,
                                          :width => 450,
                                          :height => 80)

  h_fn_field = Field.new( :name => "Husband's Name",
                        :field_key=>"husband_first_name",
                        :kind=>"text" )
  h_ln_field = Field.new( :name => "Husband's Surame",
                        :field_key=>"husband_last_name",
                        :kind=>"text" )
  w_fn_field = Field.new( :name => "Wife's Name",
                        :field_key=>"wife_first_name",
                        :kind=>"text" )
  w_ln_field = Field.new( :name => "Wife's Surame",
                        :field_key=>"wife_last_name",
                        :kind=>"text" )
  h_place_field = Field.new( :name => "Husband's Place",
                        :field_key=>"husband_place_name",
                        :kind=>"text" )
  w_place_field = Field.new( :name => "Wife's Place",
                        :field_key=>"wife_place_name",
                        :kind=>"text" )

                                  
  marriage_bicker.fields << date  
  marriage_bicker.fields << h_fn_field  
  marriage_bicker.fields << h_ln_field  
  marriage_bicker.fields << w_fn_field  
  marriage_bicker.fields << w_ln_field  
  marriage_bicker.fields << h_place_field  
  marriage_bicker.fields << w_place_field  
  marriage_bicker.fields << notes_field  



  template.entities <<  baptism_bicker
  template.entities <<  marriage_bicker
  template.entities <<  burial_bicker
  template.save 

  
end