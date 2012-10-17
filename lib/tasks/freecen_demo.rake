task :freecen_demo => :environment do
  Template.delete_all
  Entity.delete_all
  Asset.delete_all
  
  template = Template.create( :name => "My Transcription Template",
                              :description => "A template for transcribing weather recordds",
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

  #generate a single asset and a single user for testing just now
  wales1841 = AssetCollection.create(:title => "Welsh 1841 Census", :author => "", :extern_ref => "http://en.wikipedia.org/wiki/Census_in_the_United_Kingdom")
  england1841 = AssetCollection.create(:title => "English 1841 Census", :author => "", :extern_ref => "http://en.wikipedia.org/wiki/Census_in_the_United_Kingdom")

  Asset.create(:location => "/images/sample/Wales1841_crop_recto.jpg", 
    :display_width => 800, 
    :height => 2118, 
    :width => 1467, 
    :template => template, 
    :asset_collection => wales1841)
    
  Asset.create(:location => "/images/sample/England1841_crop_recto.jpg", 
    :display_width => 800, 
    :height => 2211, 
    :width => 1506, 
    :template => template, 
    :asset_collection => england1841)


  Asset.create(:location => "/images/sample/England1841_crop_verso.jpg", 
    :display_width => 800, 
    :height => 2196, 
    :width => 1440, 
    :template => template, 
    :asset_collection => england1841)

  Asset.create(:location => "/images/sample/Wales1841_crop_verso.jpg", 
    :display_width => 800, 
    :height => 2118, 
    :width => 1392, 
    :template => template, 
    :asset_collection => wales1841)





  ZooniverseUser.create()
  
end