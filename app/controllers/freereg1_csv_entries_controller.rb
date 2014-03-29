class Freereg1CsvEntriesController < InheritedResources::Base
   layout "places"
   require 'chapman_code'
    require 'freereg_validations'

  def index
  
    @register = session[:register_id] 
    @register_name = session[:register_name] 
    @church = session[:church_id]
    @church_name = session[:church_name]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name] 
     @first_name = session[:first_name]
     @user = UseridDetail.where(:userid => session[:userid]).first
    @freereg1_csv_file_name =  session[:freereg1_csv_file_name]
    @freereg1_csv_file_id = session[:freereg1_csv_file_id]
    @freereg1_csv_file = Freereg1CsvFile.find(@freereg1_csv_file_id)
    @freereg1_csv_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => @freereg1_csv_file_id ).order_by(file_line_number: 1)
  end

  def show
    load(params[:id])
  end

  def error
    session[:error_id] = params[:id]
    @church = session[:church_id]
    @church_name = session[:church_name]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name] 
    @first_name = session[:first_name]
    @freereg1_csv_file_name =  session[:freereg1_csv_file_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    error_file = @freereg1_csv_file.batch_errors.find(params[:id])
    error_file.data_line[:record_type] = error_file.record_type
    @freereg1_csv_entry = Freereg1CsvEntry.new(error_file.data_line)
    @error_line = error_file.record_number
    @error_message = error_file.error_message
    
  end
  def create
   
    @user = UseridDetail.where(:userid => session[:userid]).first
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    @freereg1_csv_entry = Freereg1CsvEntry.new(params[:freereg1_csv_entry])
    
    @freereg1_csv_file.freereg1_csv_entries << @freereg1_csv_entry
    @freereg1_csv_entry.save
    if @freereg1_csv_entry.errors.any?
     flash[:notice] = 'The creation of the record was unsuccsessful'
    
      render :action => 'error'
     else
    backup_file(@freereg1_csv_file)
    #update file with date and lock and delete error
    @freereg1_csv_file.locked = 'true'
    @freereg1_csv_file.modification_date = Time.now.strftime("%d %b %Y")
     @freereg1_csv_file.error =  @freereg1_csv_file.error - 1
    if session[:error_id].nil?
     
    @freereg1_csv_file.records = @freereg1_csv_file.records.to_i + 1 
    case 
    when @freereg1_csv_file.record_type == 'ba'
      date = params[:freereg1_csv_entry][:baptism_date]
     when @freereg1_csv_file.record_type == 'ma' 
       date = params[:freereg1_csv_entry][:marriage_date]
     when @freereg1_csv_file.record_type == 'bu' 
       date = params[:freereg1_csv_entry][:burial_date]
    end
    date = FreeregValidations.year_extract(date)
    unless date.nil?
      @freereg1_csv_file.datemax = date if date > @freereg1_csv_file.datemax
      @freereg1_csv_file.datemin = date if date < @freereg1_csv_file.datemin
      xx = ((date.to_i - 1530)/10).to_i unless date.to_i <= 1530 # avoid division into zero
      @freereg1_csv_file.daterange[xx] = @freereg1_csv_file.daterange[xx] + 1 unless (xx < 0 || xx > 50)
    end
  else
    
      
          @freereg1_csv_file.batch_errors.delete( @freereg1_csv_file.batch_errors.find(session[:error_id]))
   end
    session[:error_id] = nil
    @freereg1_csv_file.save
    flash[:notice] = 'The creation/update in entry contents was succsessful, backup of file made and locked' 
    render :action => 'show'
    end
  else
end

def new
  session[:error_id] = nil
   @church = session[:church_id]
    @church_name = session[:church_name]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name] 
    @first_name = session[:first_name]
    @freereg1_csv_file_name =  session[:freereg1_csv_file_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
     @freereg1_csv_file = Freereg1CsvFile.find( session[:freereg1_csv_file_id])
     file_line_number = @freereg1_csv_file.records.to_i + 1
     line_id = @freereg1_csv_file.userid + "." + @freereg1_csv_file.file_name.upcase + "." +  file_line_number.to_s
     @freereg1_csv_entry = Freereg1CsvEntry.new(:record_type  => @freereg1_csv_file.record_type, :line_id => line_id, :file_line_number => file_line_number )

end

  def edit
    load(params[:id])
    
  end
  def update
   
    load(params[:id])
     record_type = @freereg1_csv_file.record_type
     params[:freereg1_csv_entry][:record_type] = record_type

    @freereg1_csv_entry.update_attributes(params[:freereg1_csv_entry])
    
     @freereg1_csv_entry.save
     
     if @freereg1_csv_entry.errors.any?
     flash[:notice] = 'The update of the record was unsuccsessful'
      render :action => 'edit'
     else
   
    file = @freereg1_csv_file
  
    backup_file(file)
    file.locked = 'true'
    file.modification_date = Time.now.strftime("%d %b %Y")
    file.save
    
    flash[:notice] = 'The change in entry contents was succsessful, backup of file made and locked' 
    render :action => 'show'
    end
  end

  def load(file_id)
    @freereg1_csv_entry = Freereg1CsvEntry.find(file_id)
    session[:freereg1_csv_entry_id] = @freereg1_csv_entry._id
    @freereg1_csv_file_id =  session[:freereg1_csv_file_id]
    @freereg1_csv_file_name =  session[:freereg1_csv_file_name]
    @freereg1_csv_file = Freereg1CsvFile.find(@freereg1_csv_file_id)
   
    #@register = register.@freereg1_csv_file
    #@register_name = @register.alternate_register_name
    @church = session[:church_id]
    @church_name = session[:church_name]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name] 
    @first_name = session[:first_name]
     @user = UseridDetail.where(:userid => session[:userid]).first
     
  end

  def backup_file(file)
    #this makes aback up copu of the file in the attic and
   file_name = file.file_name
   csvdir = File.join(Rails.application.config.datafiles,file.userid)
   csvfile = File.join(csvdir,file_name)
    
      if File.file?(csvfile)
        newdir = File.join(csvdir,'.attic')
        Dir.mkdir(newdir) unless Dir.exists?(newdir)
        renamed_file = (csvfile + "." + (Time.now.to_i).to_s).to_s
        File.rename(csvfile,renamed_file)
        FileUtils.mv(renamed_file,newdir, verbose:  true)
       else 
         p "file does not exist"
        end
   csv_hold = Array.new
       if File.file?(csvfile)
          p "file should not be there"
       end
  
    CSV.open(csvfile, "wb") do |csv|
        # eg +INFO,David@davejo.eclipse.co.uk,password,SEQUENCED,BURIALS,cp850,,,,,,,
    csv << ["+INFO","#{file.transcriber_email}","PASSWORD","SEQUENCED","#{file.record_type}","#{file.characterset}"]
      # eg #,CCCC,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,,,,,,,
    csv << ['#','CCCC',file.transcriber_name,file.transcriber_syndicate,file.file_name,file.transcription_date]
      # eg #,Credit,Libby,email address,,,,,,
    csv << ['#','CREDIT',file.credit_name,file.credit_email]
       # eg #,05-Feb-2006,data taken from computer records and converted using Excel, LDS
    csv << ['#',file.modification_date,file.first_comment,file.second_comment]
       #eg +LDS,,,,
    csv << ['+LDS'] if file.lds =='yes'
    type = file.record_type
    records = file.freereg1_csv_entries
      records.each do |rec|
       case 
         when file.record_type == "ba"
         
            csv_hold =  ["#{file.county}","#{file.place}","#{file.church_name}",
             "#{rec.register_entry_number}","#{rec.birth_date}","#{rec.baptism_date}","#{rec.person_forename}","#{rec.person_sex}",
             "#{rec.father_forename}","#{rec.mother_forename}","#{rec.father_surname}","#{rec.mother_surname}","#{rec.person_abode}",
             "#{rec.father_occupation}","#{rec.notes}"]
            csv_hold =  csv_hold + ["#{rec.film}", "#{rec.film_number}"] if file.lds =='yes'
            csv << csv_hold

         when file.record_type == "bu"
           
            csv_hold = ["#{file.county}","#{file.place}","#{file.church_name}",
            "#{rec.register_entry_number}","#{rec.burial_date}","#{rec.burial_person_forename}",
            "#{rec.relationship}","#{rec.male_relative_forename}","#{rec.female_relative_forename}","#{rec.relative_surname}",
            "#{rec.burial_person_surname}","#{rec.person_age}","#{rec.burial_person_abode}","#{rec.notes}"]
            csv_hold =  csv_hold + ["#{rec.film}", "#{rec.film_number}"] if file.lds =='yes'
            csv << csv_hold
        
         when file.record_type == "ma" 
          csv_hold = ["#{file.county}","#{file.place}","#{file.church_name}",
          "#{rec.register_entry_number}","#{rec.marriage_date}","#{rec.groom_forename}","#{rec.groom_surname}","#{rec.groom_age}","#{rec.groom_parish}",
          "#{rec.groom_condition}","#{rec.groom_occupation}","#{rec.groom_abode}","#{rec.bride_forename}","#{rec.bride_surname}","#{rec.bride_age}",
          "#{rec.bride_parish}","#{rec.bride_condition}","#{rec.bride_occupation}","#{rec.bride_abode}","#{rec.groom_father_forename}","#{rec.groom_father_surname}",
          "#{rec.groom_father_occupation}","#{rec.bride_father_forename}","#{rec.bride_father_surname}","#{rec.bride_father_occupation}",
          "#{rec.witness1_forename}","#{rec.witness1_surname}","#{rec.witness2_forename}","#{rec.witness2_surname}","#{rec.notes}"]
            csv_hold =  csv_hold + ["#{rec.film}", "#{rec.film_number}"] if file.lds =='yes'
            csv << csv_hold
       end #end cas
     end #end records
    end #end csv
   end #end method
end
