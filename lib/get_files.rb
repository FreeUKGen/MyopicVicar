module GetFiles
ALPHA = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","1","2","3","4","5","6","7","8","9"]
def self.get_all_of_the_filenames(base_directory,range)
    
     filenames = Array.new
     files = Array.new
     aplha = Array.new
     alpha_start = 1
     alpha_end = 2
     alpha = range.split("-")
     if alpha[0].length == 1
       #deal with a-c range
       alpha_start = ALPHA.find_index(alpha[0])
       alpha_end =  alpha_start + 1
       alpha_end = ALPHA.find_index(alpha[1]) + 1 unless alpha.length == 1
       index = alpha_start
       while index < alpha_end do 
         #get the file names for a character 
         pattern = base_directory + ALPHA[index] + "*/*.csv" 
         files = Dir.glob(pattern, File::FNM_CASEFOLD).sort 
         files.each do |fil|
           filenames << fil
         end #end do
         index = index + 1
       end #end while
     else
      new_alpha = Array.new
      new_alpha = range.split("/")
      case
        when new_alpha[0].length > 2 && new_alpha[1].length  >= 12
         #deals with userid/abddddxy.csv ie a specific file
           files = base_directory + range
           filenames << files
        when (new_alpha[0].length == 1 || new_alpha[0].length >= 2) && new_alpha[1].length < 12 
           #deals with userid/*.csv i.e. all of a usersid files or */wry*.csv
           pattern =  base_directory + range
           files = Dir.glob(pattern, File::FNM_CASEFOLD).sort 
           files.each do |fil|
           filenames << fil
         end #end do
       end #end case
    end #end if
   return filenames
  end #end method
end #end module