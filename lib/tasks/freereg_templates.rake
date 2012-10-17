task :freereg_templates => :environment do
  Template.delete_all
  Entity.delete_all
#  Asset.delete_all
  
  template = Template.create( :name => "1841 Census",
                              :description => "A template for transcribing weather records",
                              :project => "My great project",
                              :display_width => 600,
                              :default_zoom => 1.5)
                          

  fn_field = Field.new( :name => "First Name",
                        :field_key=>"first_name",
                        :kind=>"text" )
  ln_field = Field.new( :name => "Last Name",
                        :field_key=>"last_name",
                        :kind=>"text" )
  age_male = Field.new( :name => "Age(M)", :field_key=>"age_m",:kind=>"text",
                        :options => { :text => { :max_length => 2, :min_length => 0 } })
  age_female = Field.new( :name => "Age(F)", :field_key=>"age_f",:kind=>"text",
                          :options => { :text => { :max_length => 2, :min_length => 0 } })
  profession = Field.new( :name => "Employment", :field_key=>"employment",:kind=>"text")
  where_same = Field.new( :name => "Same County?", :field_key=>"born_same_county", 
  	       		  :kind => "select",
                          :initial_value => "--",
                          :options => { :select => ['Y', 'N'] })
  where_uk = Field.new( :name => "Non-England", :field_key=>"born_non_england", 
  	       		  :kind => "select",
                          :initial_value => "--",
                          :options => { :select => ['Y', 'N'] })
  


  person_entity_1841_england = Entity.create( :name => "Person",
                                   	      :description => "Person name",
                                  	      :help => "Select any names of people you see",
                                  	      :resizeable => true,
                                  	      :width => 450,
                                  	      :height => 80)
                                  
					    
  person_entity_1841_england.fields << fn_field  
  person_entity_1841_england.fields << ln_field  
  person_entity_1841_england.fields << age_male 
  person_entity_1841_england.fields << age_female  
  person_entity_1841_england.fields << profession  
  person_entity_1841_england.fields << where_same
  person_entity_1841_england.fields << where_uk  
 

  template.entities <<  person_entity_1841_england
  template.save 

  sex_field = Field.new( :name => "Sex", :field_key=>"sex",:kind => "select", :initial_value => "--",:options => { :select => ['M', 'F'] })

  date_field  = Field.new( :name => "Date",
                        :field_key=>"date",
                        :kind=>"text" )
  ffn_field = Field.new( :name => "First Name (Father)",
                        :field_key=>"f_first_name",
                        :kind=>"text" )
  fln_field = Field.new( :name => "Last Name (Father)",
                        :field_key=>"f_last_name",
                        :kind=>"text" )
  gfn_field = Field.new( :name => "First Name (Groom)",
                        :field_key=>"g_first_name",
                        :kind=>"text" )
  gln_field = Field.new( :name => "Last Name (Groom)",
                        :field_key=>"g_last_name",
                        :kind=>"text" )
  bfn_field = Field.new( :name => "First Name (bride)",
                        :field_key=>"b_first_name",
                        :kind=>"text" )
  bln_field = Field.new( :name => "Last Name (Bride)",
                        :field_key=>"b_last_name",
                        :kind=>"text" )

  basic_template = Template.create( :name => "Basic Registers 2",
                              :description => "A template for transcribing basic register entries",
                              :project => "My great project",
                              :display_width => 600,
                              :default_zoom => 1.5)
                          
  baptism_entity_basic = Entity.create( :name => "Baptism",
                                          :description => "Person name",
                                          :help => "Select any names of people you see",
                                          :resizeable => true,
                                          :width => 450,
                                          :height => 80)
  burial_entity_basic = Entity.create( :name => "Burial",
                                          :description => "Person name",
                                          :help => "Select any names of people you see",
                                          :resizeable => true,
                                          :width => 450,
                                          :height => 80)
  marriage_entity_basic = Entity.create( :name => "Marriage",
                                          :description => "Person name",
                                          :help => "Select any names of people you see",
                                          :resizeable => true,
                                          :width => 450,
                                          :height => 80)

  baptism_entity_basic.fields << fn_field
  baptism_entity_basic.fields << date_field
  baptism_entity_basic.fields << ffn_field
  baptism_entity_basic.fields << fln_field

  burial_entity_basic.fields << fn_field
  burial_entity_basic.fields << ln_field
  burial_entity_basic.fields << date_field

  marriage_entity_basic.fields << gfn_field
  marriage_entity_basic.fields << gln_field
  marriage_entity_basic.fields << date_field
  marriage_entity_basic.fields << bfn_field
  marriage_entity_basic.fields << bln_field

  basic_template.entities << baptism_entity_basic
  basic_template.entities << burial_entity_basic
  basic_template.entities << marriage_entity_basic
  basic_template.save
  
  #generate a single asset and a single user for testing just now
#
#  Asset.create(:location => "/images/sample/Wales1841_crop_recto.jpg", 
#    :display_width => 800, 
#    :height => 2118, 
#    :width => 1467, 
#    :template => template, 
#    :asset_collection => wales1841)
#    
#  Asset.create(:location => "/images/sample/England1841_crop_recto.jpg", 
#    :display_width => 800, 
#    :height => 2211, 
#    :width => 1506, 
#    :template => template, 
#    :asset_collection => england1841)
#
#
#  Asset.create(:location => "/images/sample/England1841_crop_verso.jpg", 
#    :display_width => 800, 
#    :height => 2196, 
#    :width => 1440, 
#    :template => template, 
#    :asset_collection => england1841)
#
#  Asset.create(:location => "/images/sample/Wales1841_crop_verso.jpg", 
#    :display_width => 800, 
#    :height => 2118, 
#    :width => 1392, 
#    :template => template, 
#    :asset_collection => wales1841)




  
end