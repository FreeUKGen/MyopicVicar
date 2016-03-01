desc "Initialize the emendation rules"


task :load_emendations => :environment do  
  THIS_RAKE_TASK = 'load_emendations rake task'
  ets = EmendationType.where(:origin => THIS_RAKE_TASK)
  ets.each do |et|
    et.emendation_rules.delete_all
    et.delete
  end
  et = EmendationType.create!(:name => 'expansion', :target_field => :first_name, :origin => THIS_RAKE_TASK)
  EmendationRule.create!(:original => 'abig', :replacement => 'abigail', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'abm', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  EmendationRule.create!(:original => 'abra', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  EmendationRule.create!(:original => 'abrah', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  EmendationRule.create!(:original => 'abraha', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  EmendationRule.create!(:original => 'abrahm', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  EmendationRule.create!(:original => 'abram', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  EmendationRule.create!(:original => 'abrm', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  EmendationRule.create!(:original => 'abr', :replacement => 'abraham', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'agn', :replacement => 'agnes', :emendation_type => et)
  EmendationRule.create!(:original => 'alex', :replacement => 'alexander', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'alex', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'alexand', :replacement => 'alexander', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'alexand', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'alexandr', :replacement => 'alexander', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'alexandr', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'alexdr', :replacement => 'alexander', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'alexdr', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'alexr', :replacement => 'alexander', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'alexr', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'alf', :replacement => 'alfred', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'alic', :replacement => 'alice', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'allex', :replacement => 'alexander', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'allex', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'amb', :replacement => 'ambrose', :emendation_type => et)
  EmendationRule.create!(:original => 'and', :replacement => 'andrew', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'andr', :replacement => 'andrew', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'andw', :replacement => 'andrew', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'ant', :replacement => 'anthony', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'anth', :replacement => 'anthony', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'antho', :replacement => 'anthony', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'anthy', :replacement => 'anthony', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'anto', :replacement => 'anthony', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'anty', :replacement => 'anthony', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'arch', :replacement => 'archibald', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'archd', :replacement => 'archibald', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'art', :replacement => 'arthur', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'arth', :replacement => 'arthur', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'atha', :replacement => 'agatha', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'aug', :replacement => 'augustus', :emendation_type => et)
  EmendationRule.create!(:original => 'barb', :replacement => 'barbara', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'barba', :replacement => 'barbara', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'bart', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'barth', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'bartho', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'barthol', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'barthw', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'barw', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'ben', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'benj', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'benja', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'benjam', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'benjamn', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'benjan', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'benjm', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'benjn', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'benn', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'brid', :replacement => 'bridget', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'bridgt', :replacement => 'bridget', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'cath', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#sdx
  EmendationRule.create!(:original => 'cath', :replacement => 'catherine', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'catha', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'cathar', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'cathe', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'cather', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'cathn', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#sdx
  EmendationRule.create!(:original => 'cathn', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'cathne', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#sdx
  EmendationRule.create!(:original => 'cathne', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'cathr', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#sdx
  EmendationRule.create!(:original => 'cathr', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'cathrn', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#sdx
  EmendationRule.create!(:original => 'cathrn', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'cha', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'char', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'charl', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'charls', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'chars', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'chas', :replacement => 'charles', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'chris', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'chrisr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christ', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christo', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christop', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christoph', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christophr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christopr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'chro', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'chrs', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'clem', :replacement => 'clement', :emendation_type => et)
  EmendationRule.create!(:original => 'clemt', :replacement => 'clement', :emendation_type => et)#
  EmendationRule.create!(:original => 'const', :replacement => 'constance', :emendation_type => et)
  EmendationRule.create!(:original => 'corn', :replacement => 'cornelius', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'cuth', :replacement => 'cuthbert', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'cuthbt', :replacement => 'cuthbert', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'cutht', :replacement => 'cuthbert', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'dan', :replacement => 'daniel', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'danl', :replacement => 'daniel', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'danll', :replacement => 'daniel', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'dav', :replacement => 'david', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'davd', :replacement => 'david', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'deb', :replacement => 'deborah', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'den', :replacement => 'dennis', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'don', :replacement => 'donald', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'dor', :replacement => 'dorothy', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'doro', :replacement => 'dorothy', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'doroth', :replacement => 'dorothy', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'dory', :replacement => 'dorothy', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'doug', :replacement => 'douglas', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'dy', :replacement => 'dorothy', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'ed', :replacement => 'edmund', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'ed', :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'edd', :replacement => 'edmund', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'edd', :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'edm', :replacement => 'edmund', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'edmd', :replacement => 'edmund', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'edrus', :replacement => 'edward', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'edw', :replacement => 'edward', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'edwd', :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'edwrd', :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'eleanr', :replacement => 'eleanor', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elear', :replacement => 'eleanor', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'eli', :replacement => 'elias', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'elis', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elisa', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elisab', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elisabth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elisath', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elish', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elisth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elith', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elisath', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elisath', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elisath', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'eliz', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'elizab', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizabh', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizabth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizae', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizah', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizath', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizb', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizbeth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizbt', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizbth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizh', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizt', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'elizth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "eliz'th", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "elliz", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "ellizab", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "elsab", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "elsp", :replacement => 'elspeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "elyz", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "elyzab", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "elz", :replacement => 'eliza', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "elz", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "elzab", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "elzth", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "em", :replacement => 'emma', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "em", :replacement => 'emily', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "emm", :replacement => 'emma', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "emm", :replacement => 'emily', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'esth', :replacement => 'esther', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'ezek', :replacement => 'ezekiel', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => "ewd", :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "fra", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "fra", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "fran", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "fran", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "franc", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "franc", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "franc", :replacement => 'franchesca', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "francs", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "francs", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "francs", :replacement => 'franchesca', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "frans", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "frans", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "frans", :replacement => 'franchesca', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "fras", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "fras", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "fras", :replacement => 'franchesca', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'fred', :replacement => 'frederick', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'fredk', :replacement => 'frederick', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'froo', :replacement => 'franco', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'fs', :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'fs', :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'gab', :replacement => 'gabriel', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'gab', :replacement => 'gabrielle', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'gab', :replacement => 'gabriella', :emendation_type => et, :gender => 'f')#sdx
  EmendationRule.create!(:original => 'geo', :replacement => 'george', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'geoe', :replacement => 'george', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'geor', :replacement => 'george', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'georg', :replacement => 'george', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'geof', :replacement => 'geoffrey', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'gilb', :replacement => 'gilbert', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'gilbt', :replacement => 'gilbert', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'godf', :replacement => 'godfrey', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'gr', :replacement => 'griffith', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'greg', :replacement => 'gregory', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'griffth', :replacement => 'griffith', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'guil', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'guil', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'guilieli', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'guilieli', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'gul', :replacement => 'william', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'gul', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'guli', :replacement => 'william', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'guli', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'guliel', :replacement => 'william', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'guliel', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'gulielm', :replacement => 'william', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'gulielm', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'gulielmi', :replacement => 'william', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'gulielmi', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'gull', :replacement => 'william', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'gull', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'han', :replacement => 'hannah', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'hanh', :replacement => 'hannah', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'hann', :replacement => 'hannah', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'hannh', :replacement => 'hannah', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'hel', :replacement => 'helen', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'hen', :replacement => 'henry', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'henr', :replacement => 'henry', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'henric', :replacement => 'henrici', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'henric', :replacement => 'henry', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'henrici', :replacement => 'henry', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'heny', :replacement => 'henry', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'herb', :replacement => 'herbert', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'hump', :replacement => 'humphrey', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'humph', :replacement => 'humphrey', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'humphr', :replacement => 'humphrey', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'humpy', :replacement => 'humphrey', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'hy', :replacement => 'henry', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'illeg', :replacement => 'illegitimus', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'ioh', :replacement => 'john', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'isa', :replacement => 'isaiah', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'isa', :replacement => 'isabel', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'isa', :replacement => 'isabella', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'isab', :replacement => 'isabel', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'isab', :replacement => 'isabella', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'isaba', :replacement => 'isabel', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'isaba', :replacement => 'isabella', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'isb', :replacement => 'isabel', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'jabus', :replacement => 'james', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'jac', :replacement => 'james', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'jas', :replacement => 'james', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'jeff', :replacement => 'jeffery', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'jer', :replacement => 'jeremiah', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'jer', :replacement => 'jeremy', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jere', :replacement => 'jeremy', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jere', :replacement => 'jeremiah', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jerem', :replacement => 'jeremy', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jerem', :replacement => 'jeremiah', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jeremh', :replacement => 'jeremy', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jeremh', :replacement => 'jeremiah', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jerh', :replacement => 'jeremy', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jerh', :replacement => 'jeremiah', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jhn', :replacement => 'john', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jho', :replacement => 'john', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jno', :replacement => 'john', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'joh', :replacement => 'johannes', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'joha', :replacement => 'johanna', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'johan', :replacement => 'johanna', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'johan', :replacement => 'johannes', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'johes', :replacement => 'johannes', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'johis', :replacement => 'johannis', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'johnes', :replacement => 'johannes', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jon', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'jona', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jonan', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jonat', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jonath', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jonathn', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jonn', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jos', :replacement => 'joseph', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'josa', :replacement => 'joshua', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'josh', :replacement => 'josiah', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'josp', :replacement => 'joseph', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'josph', :replacement => 'joseph', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jsp', :replacement => 'joseph', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jud', :replacement => 'judith', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'jud', :replacement => 'judas', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'kat', :replacement => 'katherine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'kat', :replacement => 'katharine', :emendation_type => et, :gender => 'f')#sdx
  EmendationRule.create!(:original => 'kath', :replacement => 'katherine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'kath', :replacement => 'katharine', :emendation_type => et, :gender => 'f')#sdx
  EmendationRule.create!(:original => 'kathar', :replacement => 'katharine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'kather', :replacement => 'katherine', :emendation_type => et, :gender => 'f')#sdx
  EmendationRule.create!(:original => 'kathr', :replacement => 'katherine', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'kathr', :replacement => 'katharine', :emendation_type => et, :gender => 'f')#sdx
  EmendationRule.create!(:original => 'lanc', :replacement => 'lancelot', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'lau', :replacement => 'laurence', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'laur', :replacement => 'laurence', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'law', :replacement => 'lawrence', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'lawr', :replacement => 'lawrence', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'leo', :replacement => 'leonard', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'leon', :replacement => 'leonard', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'leond', :replacement => 'leonard', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'lyd', :replacement => 'lydia', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'mag', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'mags', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'magt', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'mar', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'marg', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'marga', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'margar', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'margart', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'margat', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'marget', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'margrt', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'margt', :replacement => 'margaret', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'margtt', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => 'math', :replacement => 'matthias', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'matt', :replacement => 'matthew', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'mau', :replacement => 'maurice', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'mich', :replacement => 'michael', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'micls', :replacement => 'michael', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'mill', :replacement => 'millicent', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'my', :replacement => 'mary', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'nath', :replacement => 'nathaniel', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'nich', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'nics', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'ol', :replacement => 'oliver', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'pat', :replacement => 'patrick', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'pen', :replacement => 'penelope', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'pet', :replacement => 'peter', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'phil', :replacement => 'philip', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'phin', :replacement => 'phineas', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'phyl', :replacement => 'phyllis', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'prisc', :replacement => 'priscilla', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'pru', :replacement => 'prudence', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'rach', :replacement => 'rachel', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'ray', :replacement => 'raymond', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'reb', :replacement => 'rebecca', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'reg', :replacement => 'reginald', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'ric', :replacement => 'richard', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'richdus', :replacement => 'richard', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'robt', :replacement => 'robert', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'rog', :replacement => 'roger', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'saml', :replacement => 'samuel', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'sar', :replacement => 'sarah', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'silv', :replacement => 'sylvester', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'sim', :replacement => 'simon', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'sol', :replacement => 'solomon', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'ste', :replacement => 'stephen', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'sus', :replacement => 'susan', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'susna', :replacement => 'susanna', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'theo', :replacement => 'theodore', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'thos', :replacement => 'thomas', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'tim', :replacement => 'timothy', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'urs', :replacement => 'ursula', :emendation_type => et, :gender => 'f')
  EmendationRule.create!(:original => 'val', :replacement => 'valentine', :emendation_type => et)
  EmendationRule.create!(:original => 'vinc', :replacement => 'vincent', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'walt', :replacement => 'walter', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'win', :replacement => 'winifred', :emendation_type => et)
  EmendationRule.create!(:original => 'wm', :replacement => 'william', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'xpr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'xtianus', :replacement => 'christian', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'xtopherus', :replacement => 'christopher', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => 'zach', :replacement => 'zachariah', :emendation_type => et, :gender => 'm')

  et = EmendationType.create!(:name => 'delatinization', :target_field => :first_name, :origin => THIS_RAKE_TASK)
  EmendationRule.create!(:original => 'adamus', :replacement => 'adam', :emendation_type => et)
  EmendationRule.create!(:original => 'adelmarus', :replacement => 'elmer', :emendation_type => et)
  EmendationRule.create!(:original => 'adrianus', :replacement => 'adrian', :emendation_type => et)
  EmendationRule.create!(:original => 'aegidius', :replacement => 'giles', :emendation_type => et)
  EmendationRule.create!(:original => 'aemilia', :replacement => 'emily', :emendation_type => et)
  EmendationRule.create!(:original => 'aemilius', :replacement => 'emile', :emendation_type => et)
  EmendationRule.create!(:original => 'alanus', :replacement => 'alan', :emendation_type => et)
  EmendationRule.create!(:original => 'albanus', :replacement => 'alban', :emendation_type => et)
  EmendationRule.create!(:original => 'albertus', :replacement => 'albert', :emendation_type => et)
  EmendationRule.create!(:original => 'albinus', :replacement => 'albin', :emendation_type => et)
  EmendationRule.create!(:original => 'alcuinus', :replacement => 'alcuin', :emendation_type => et)
  EmendationRule.create!(:original => 'alexius', :replacement => 'alexis', :emendation_type => et)
  EmendationRule.create!(:original => 'alfredus', :replacement => 'alfred', :emendation_type => et)
  EmendationRule.create!(:original => 'alfridus', :replacement => 'alfred', :emendation_type => et)
  EmendationRule.create!(:original => 'alicia', :replacement => 'alice', :emendation_type => et)
  EmendationRule.create!(:original => 'aloysius', :replacement => 'aloys', :emendation_type => et)
  EmendationRule.create!(:original => 'alphonsus', :replacement => 'alphonse', :emendation_type => et)
  EmendationRule.create!(:original => 'aluinus', :replacement => 'alvin', :emendation_type => et)
  EmendationRule.create!(:original => 'amabilia', :replacement => 'mabel', :emendation_type => et)
  EmendationRule.create!(:original => 'amata', :replacement => 'amy', :emendation_type => et)
  EmendationRule.create!(:original => 'ambrosius', :replacement => 'ambrose', :emendation_type => et)
  EmendationRule.create!(:original => 'americus', :replacement => 'emery', :emendation_type => et)
  EmendationRule.create!(:original => 'anatolius', :replacement => 'anatole', :emendation_type => et)
  EmendationRule.create!(:original => 'andreas', :replacement => 'andrew', :emendation_type => et)
  EmendationRule.create!(:original => 'anna', :replacement => 'ann', :emendation_type => et)
  EmendationRule.create!(:original => 'ansgarus', :replacement => 'oscar', :emendation_type => et)
  EmendationRule.create!(:original => 'anselmus', :replacement => 'anselm', :emendation_type => et)
  EmendationRule.create!(:original => 'antonius', :replacement => 'anthony', :emendation_type => et)
  EmendationRule.create!(:original => 'archibaldus', :replacement => 'archibald', :emendation_type => et)
  EmendationRule.create!(:original => 'arduinus', :replacement => 'hardwin', :emendation_type => et)
  EmendationRule.create!(:original => 'armandus', :replacement => 'herman', :emendation_type => et)
  EmendationRule.create!(:original => 'arnaldus', :replacement => 'arnold', :emendation_type => et)
  EmendationRule.create!(:original => 'arnoldus', :replacement => 'arnold', :emendation_type => et)
  EmendationRule.create!(:original => 'arnulfus', :replacement => 'arnulf', :emendation_type => et)
  EmendationRule.create!(:original => 'arthurus', :replacement => 'arthur', :emendation_type => et)
  EmendationRule.create!(:original => 'artorius', :replacement => 'arthur', :emendation_type => et)
  EmendationRule.create!(:original => 'augustinus', :replacement => 'austin', :emendation_type => et)
  EmendationRule.create!(:original => 'baldovinus', :replacement => 'baldwin', :emendation_type => et)
  EmendationRule.create!(:original => 'barnabas', :replacement => 'barnaby', :emendation_type => et)
  EmendationRule.create!(:original => 'basilius', :replacement => 'basil', :emendation_type => et)
  EmendationRule.create!(:original => 'beatrix', :replacement => 'beatrice', :emendation_type => et)
  EmendationRule.create!(:original => 'bernardus', :replacement => 'bernard', :emendation_type => et)
  EmendationRule.create!(:original => 'berylia', :replacement => 'beryl', :emendation_type => et)
  EmendationRule.create!(:original => 'blanca', :replacement => 'blanche', :emendation_type => et)
  EmendationRule.create!(:original => 'blasius', :replacement => 'blase', :emendation_type => et)
  EmendationRule.create!(:original => 'bonifatius', :replacement => 'boniface', :emendation_type => et)
  EmendationRule.create!(:original => 'brigitta', :replacement => 'bridget', :emendation_type => et)
  EmendationRule.create!(:original => 'caecilia', :replacement => 'cecilia', :emendation_type => et)
  EmendationRule.create!(:original => 'caecilius', :replacement => 'cecil', :emendation_type => et)
  EmendationRule.create!(:original => 'caritas', :replacement => 'charity', :emendation_type => et)
  EmendationRule.create!(:original => 'carola', :replacement => 'carol', :emendation_type => et)
  EmendationRule.create!(:original => 'carolus', :replacement => 'charles', :emendation_type => et)
  EmendationRule.create!(:original => 'catharina', :replacement => 'catherine', :emendation_type => et)
  EmendationRule.create!(:original => 'christina', :replacement => 'christine', :emendation_type => et)
  EmendationRule.create!(:original => 'christianus', :replacement => 'christian', :emendation_type => et)
  EmendationRule.create!(:original => 'christophorus', :replacement => 'christopher', :emendation_type => et)
  EmendationRule.create!(:original => 'clara', :replacement => 'clare', :emendation_type => et)
  EmendationRule.create!(:original => 'claudia', :replacement => 'claudette', :emendation_type => et)
  EmendationRule.create!(:original => 'claudius', :replacement => 'claude', :emendation_type => et)
  EmendationRule.create!(:original => 'clemens', :replacement => 'clement', :emendation_type => et)
  EmendationRule.create!(:original => 'clementina', :replacement => 'clementine', :emendation_type => et)
  EmendationRule.create!(:original => 'clestina', :replacement => 'celeste', :emendation_type => et)
  EmendationRule.create!(:original => 'colomanus', :replacement => 'coleman', :emendation_type => et)
  EmendationRule.create!(:original => 'conradus', :replacement => 'conrad', :emendation_type => et)
  EmendationRule.create!(:original => 'constans', :replacement => 'constant', :emendation_type => et)
  EmendationRule.create!(:original => 'constantia', :replacement => 'constance', :emendation_type => et)
  EmendationRule.create!(:original => 'constantinus', :replacement => 'constantine', :emendation_type => et)
  EmendationRule.create!(:original => 'crispinus', :replacement => 'crispin', :emendation_type => et)
  EmendationRule.create!(:original => 'cyrillus', :replacement => 'cyril', :emendation_type => et)
  EmendationRule.create!(:original => 'dionysia', :replacement => 'denise', :emendation_type => et)
  EmendationRule.create!(:original => 'dionysius', :replacement => 'dennis', :emendation_type => et)
  EmendationRule.create!(:original => 'dominicus', :replacement => 'dominic', :emendation_type => et)
  EmendationRule.create!(:original => 'donivaldus', :replacement => 'donald', :emendation_type => et)
  EmendationRule.create!(:original => 'dorothea', :replacement => 'dorothy', :emendation_type => et)
  EmendationRule.create!(:original => 'edmundus', :replacement => 'edmund', :emendation_type => et)
  EmendationRule.create!(:original => 'eduardus', :replacement => 'edward', :emendation_type => et)
  EmendationRule.create!(:original => 'eleonora', :replacement => 'eleanor', :emendation_type => et)
  EmendationRule.create!(:original => 'elias', :replacement => 'elijah', :emendation_type => et)
  EmendationRule.create!(:original => 'elisabeth', :replacement => 'elizabeth', :emendation_type => et)
  EmendationRule.create!(:original => 'eloisa', :replacement => 'heloise', :emendation_type => et)
  EmendationRule.create!(:original => 'erica', :replacement => 'heather', :emendation_type => et)
  EmendationRule.create!(:original => 'ericus', :replacement => 'eric', :emendation_type => et)
  EmendationRule.create!(:original => 'ernestus', :replacement => 'ernest', :emendation_type => et)
  EmendationRule.create!(:original => 'eugenius', :replacement => 'eugene', :emendation_type => et)
  EmendationRule.create!(:original => 'eva', :replacement => 'eve', :emendation_type => et)
  EmendationRule.create!(:original => 'everardus', :replacement => 'everett', :emendation_type => et)
  EmendationRule.create!(:original => 'fabianus', :replacement => 'fabian', :emendation_type => et)
  EmendationRule.create!(:original => 'felicia', :replacement => 'felicia', :emendation_type => et)
  EmendationRule.create!(:original => 'felicitas', :replacement => 'felicity', :emendation_type => et)
  EmendationRule.create!(:original => 'ferdinandus', :replacement => 'ferdinand', :emendation_type => et)
  EmendationRule.create!(:original => 'fides', :replacement => 'faith', :emendation_type => et)
  EmendationRule.create!(:original => 'florentia', :replacement => 'florence', :emendation_type => et)
  EmendationRule.create!(:original => 'franciscus', :replacement => 'francis', :emendation_type => et)
  EmendationRule.create!(:original => 'fridericus', :replacement => 'frederick', :emendation_type => et)
  EmendationRule.create!(:original => 'galfridus', :replacement => 'walfred', :emendation_type => et)
  EmendationRule.create!(:original => 'gasparus', :replacement => 'jasper', :emendation_type => et)
  EmendationRule.create!(:original => 'gaudentia', :replacement => 'joy', :emendation_type => et)
  EmendationRule.create!(:original => 'georgius', :replacement => 'george', :emendation_type => et)
  EmendationRule.create!(:original => 'geraldus', :replacement => 'gerald', :emendation_type => et)
  EmendationRule.create!(:original => 'gerardus', :replacement => 'gerard', :emendation_type => et)
  EmendationRule.create!(:original => 'gertrudis', :replacement => 'gertrude', :emendation_type => et)
  EmendationRule.create!(:original => 'gervasius', :replacement => 'jarvis', :emendation_type => et)
  EmendationRule.create!(:original => 'gilbertus', :replacement => 'wilbert', :emendation_type => et)
  EmendationRule.create!(:original => 'gloria', :replacement => 'gloria', :emendation_type => et)
  EmendationRule.create!(:original => 'godefridus', :replacement => 'geoffrey', :emendation_type => et)
  EmendationRule.create!(:original => 'gratia', :replacement => 'grace', :emendation_type => et)
  EmendationRule.create!(:original => 'gregorius', :replacement => 'gregory', :emendation_type => et)
  EmendationRule.create!(:original => 'gualcherius', :replacement => 'walter', :emendation_type => et)
  EmendationRule.create!(:original => 'gualterus', :replacement => 'walter', :emendation_type => et)
  EmendationRule.create!(:original => 'guerinus', :replacement => 'warren', :emendation_type => et)
  EmendationRule.create!(:original => 'guernerus', :replacement => 'warner', :emendation_type => et)
  EmendationRule.create!(:original => 'guglielmus', :replacement => 'william', :emendation_type => et)
  EmendationRule.create!(:original => 'guido', :replacement => 'guy', :emendation_type => et)
  EmendationRule.create!(:original => 'gulielmus', :replacement => 'william', :emendation_type => et)
  EmendationRule.create!(:original => 'gustavus', :replacement => 'gustave', :emendation_type => et)
  EmendationRule.create!(:original => 'hacuinus', :replacement => 'hacon', :emendation_type => et)
  EmendationRule.create!(:original => 'hadrianus', :replacement => 'adrian', :emendation_type => et)
  EmendationRule.create!(:original => 'harmonia', :replacement => 'harmony', :emendation_type => et)
  EmendationRule.create!(:original => 'haraldus', :replacement => 'harold', :emendation_type => et)
  EmendationRule.create!(:original => 'helena', :replacement => 'helen', :emendation_type => et)
  EmendationRule.create!(:original => 'henricus', :replacement => 'henry', :emendation_type => et)
  EmendationRule.create!(:original => 'henrica', :replacement => 'henrietta', :emendation_type => et)
  EmendationRule.create!(:original => 'herbertus', :replacement => 'herbert', :emendation_type => et)
  EmendationRule.create!(:original => 'heribertus', :replacement => 'herbert', :emendation_type => et)
  EmendationRule.create!(:original => 'hermanus', :replacement => 'herman', :emendation_type => et)
  EmendationRule.create!(:original => 'hieronymus', :replacement => 'jerome', :emendation_type => et)
  EmendationRule.create!(:original => 'hilaria', :replacement => 'hilary', :emendation_type => et)
  EmendationRule.create!(:original => 'hilarius', :replacement => 'hilary', :emendation_type => et)
  EmendationRule.create!(:original => 'homerus', :replacement => 'homer', :emendation_type => et)
  EmendationRule.create!(:original => 'honoria', :replacement => 'honor', :emendation_type => et)
  EmendationRule.create!(:original => 'horatius', :replacement => 'horace', :emendation_type => et)
  EmendationRule.create!(:original => 'huardus', :replacement => 'howard', :emendation_type => et)
  EmendationRule.create!(:original => 'hubertus', :replacement => 'hubert', :emendation_type => et)
  EmendationRule.create!(:original => 'hugo', :replacement => 'hugo', :emendation_type => et)
  EmendationRule.create!(:original => 'hyacintha', :replacement => 'hyacinth', :emendation_type => et)
  EmendationRule.create!(:original => 'ignatius', :replacement => 'ignatius', :emendation_type => et)
  EmendationRule.create!(:original => 'iolantha', :replacement => 'yolanda', :emendation_type => et)
  EmendationRule.create!(:original => 'isaac', :replacement => 'isaac', :emendation_type => et)
  EmendationRule.create!(:original => 'isai', :replacement => 'jesse', :emendation_type => et)
  EmendationRule.create!(:original => 'ishachus', :replacement => 'isaac', :emendation_type => et)
  EmendationRule.create!(:original => 'isidorus', :replacement => 'isidore', :emendation_type => et)
  EmendationRule.create!(:original => 'jacoba', :replacement => 'jacqueline', :emendation_type => et)
  EmendationRule.create!(:original => 'jacobus', :replacement => 'james', :emendation_type => et)
  EmendationRule.create!(:original => 'jacomus', :replacement => 'james', :emendation_type => et)
  EmendationRule.create!(:original => 'jeremias', :replacement => 'jeremy', :emendation_type => et)
  EmendationRule.create!(:original => 'jesaias', :replacement => 'isaiah', :emendation_type => et)
  EmendationRule.create!(:original => 'johanna', :replacement => 'joan', :emendation_type => et)
  EmendationRule.create!(:original => 'johannes', :replacement => 'john', :emendation_type => et)
  EmendationRule.create!(:original => 'johannis', :replacement => 'john', :emendation_type => et)
  EmendationRule.create!(:original => 'jonas', :replacement => 'jonah', :emendation_type => et)
  EmendationRule.create!(:original => 'jordanus', :replacement => 'jordan', :emendation_type => et)
  EmendationRule.create!(:original => 'josephina', :replacement => 'josephine', :emendation_type => et)
  EmendationRule.create!(:original => 'josephus', :replacement => 'joseph', :emendation_type => et)
  EmendationRule.create!(:original => 'josua', :replacement => 'joshua', :emendation_type => et)
  EmendationRule.create!(:original => 'julia', :replacement => 'julie', :emendation_type => et)
  EmendationRule.create!(:original => 'juliana', :replacement => 'gillian', :emendation_type => et)
  EmendationRule.create!(:original => 'julianus', :replacement => 'julian', :emendation_type => et)
  EmendationRule.create!(:original => 'julius', :replacement => 'jules', :emendation_type => et)
  EmendationRule.create!(:original => 'justina', :replacement => 'justine', :emendation_type => et)
  EmendationRule.create!(:original => 'justinus', :replacement => 'justin', :emendation_type => et)
  EmendationRule.create!(:original => 'ladislaus', :replacement => 'vladislav', :emendation_type => et)
  EmendationRule.create!(:original => 'laurentius', :replacement => 'laurence', :emendation_type => et)
  EmendationRule.create!(:original => 'leo', :replacement => 'leon', :emendation_type => et)
  EmendationRule.create!(:original => 'leonardus', :replacement => 'leonard', :emendation_type => et)
  EmendationRule.create!(:original => 'leopoldus', :replacement => 'leopold', :emendation_type => et)
  EmendationRule.create!(:original => 'livius', :replacement => 'livy', :emendation_type => et)
  EmendationRule.create!(:original => 'lotharius', :replacement => 'luther', :emendation_type => et)
  EmendationRule.create!(:original => 'lucas', :replacement => 'luke', :emendation_type => et)
  EmendationRule.create!(:original => 'lucia', :replacement => 'lucy', :emendation_type => et)
  EmendationRule.create!(:original => 'ludovica', :replacement => 'louisa', :emendation_type => et)
  EmendationRule.create!(:original => 'ludovicus', :replacement => 'lewis', :emendation_type => et)
  EmendationRule.create!(:original => 'magdalena', :replacement => 'magdalen', :emendation_type => et)
  EmendationRule.create!(:original => 'marcellus', :replacement => 'marcel', :emendation_type => et)
  EmendationRule.create!(:original => 'marcus', :replacement => 'mark', :emendation_type => et)
  EmendationRule.create!(:original => 'margaretha', :replacement => 'margaret', :emendation_type => et)
  EmendationRule.create!(:original => 'martinus', :replacement => 'martin', :emendation_type => et)
  EmendationRule.create!(:original => 'maria', :replacement => 'mary', :emendation_type => et)
  EmendationRule.create!(:original => 'marianna', :replacement => 'marian', :emendation_type => et)
  EmendationRule.create!(:original => 'mathilda', :replacement => 'matilda', :emendation_type => et)
  EmendationRule.create!(:original => 'matthaeus', :replacement => 'matthew', :emendation_type => et)
  EmendationRule.create!(:original => 'mauritius', :replacement => 'maurice', :emendation_type => et)
  EmendationRule.create!(:original => 'maximus', :replacement => 'maxime', :emendation_type => et)
  EmendationRule.create!(:original => 'maximilianus', :replacement => 'maximilian', :emendation_type => et)
  EmendationRule.create!(:original => 'nicola', :replacement => 'nicole', :emendation_type => et)
  EmendationRule.create!(:original => 'nicolaus', :replacement => 'nicholas', :emendation_type => et)
  EmendationRule.create!(:original => 'natalia', :replacement => 'natalie', :emendation_type => et)
  EmendationRule.create!(:original => 'natalis', :replacement => 'noel', :emendation_type => et)
  EmendationRule.create!(:original => 'norbertus', :replacement => 'norbert', :emendation_type => et)
  EmendationRule.create!(:original => 'oliverus', :replacement => 'oliver', :emendation_type => et)
  EmendationRule.create!(:original => 'onuphrius', :replacement => 'humphrey', :emendation_type => et)
  EmendationRule.create!(:original => 'pancratius', :replacement => 'pancras', :emendation_type => et)
  EmendationRule.create!(:original => 'paschalis', :replacement => 'pascal', :emendation_type => et)
  EmendationRule.create!(:original => 'patricius', :replacement => 'patrick', :emendation_type => et)
  EmendationRule.create!(:original => 'paula', :replacement => 'paula', :emendation_type => et)
  EmendationRule.create!(:original => 'paulus', :replacement => 'paul', :emendation_type => et)
  EmendationRule.create!(:original => 'perla', :replacement => 'pearl', :emendation_type => et)
  EmendationRule.create!(:original => 'petrus', :replacement => 'peter', :emendation_type => et)
  EmendationRule.create!(:original => 'philippus', :replacement => 'philip', :emendation_type => et)
  EmendationRule.create!(:original => 'prudentia', :replacement => 'prudence', :emendation_type => et)
  EmendationRule.create!(:original => 'quintinus', :replacement => 'quentin', :emendation_type => et)
  EmendationRule.create!(:original => 'raimundus', :replacement => 'raymond', :emendation_type => et)
  EmendationRule.create!(:original => 'renata', :replacement => 'renee', :emendation_type => et)
  EmendationRule.create!(:original => 'renatus', :replacement => 'rene', :emendation_type => et)
  EmendationRule.create!(:original => 'ricardus', :replacement => 'richard', :emendation_type => et)
  EmendationRule.create!(:original => 'robertus', :replacement => 'robert', :emendation_type => et)
  EmendationRule.create!(:original => 'rochus', :replacement => 'rocky', :emendation_type => et)
  EmendationRule.create!(:original => 'rodgerus', :replacement => 'roger', :emendation_type => et)
  EmendationRule.create!(:original => 'rolandus', :replacement => 'roland', :emendation_type => et)
  EmendationRule.create!(:original => 'romanus', :replacement => 'roman', :emendation_type => et)
  EmendationRule.create!(:original => 'ronaldus', :replacement => 'ronald', :emendation_type => et)
  EmendationRule.create!(:original => 'rosa', :replacement => 'rose', :emendation_type => et)
  EmendationRule.create!(:original => 'rubina', :replacement => 'ruby', :emendation_type => et)
  EmendationRule.create!(:original => 'rudolphus', :replacement => 'rudolph', :emendation_type => et)
  EmendationRule.create!(:original => 'rupertus', :replacement => 'robert', :emendation_type => et)
  EmendationRule.create!(:original => 'salomo', :replacement => 'solomon', :emendation_type => et)
  EmendationRule.create!(:original => 'sara', :replacement => 'sarah', :emendation_type => et)
  EmendationRule.create!(:original => 'saulus', :replacement => 'saul', :emendation_type => et)
  EmendationRule.create!(:original => 'sergius', :replacement => 'serge', :emendation_type => et)
  EmendationRule.create!(:original => 'servatius', :replacement => 'servatius', :emendation_type => et)
  EmendationRule.create!(:original => 'sidonius', :replacement => 'sidney', :emendation_type => et)
  EmendationRule.create!(:original => 'simona', :replacement => 'simone', :emendation_type => et)
  EmendationRule.create!(:original => 'simonis', :replacement => 'simon', :emendation_type => et)
  EmendationRule.create!(:original => 'spes', :replacement => 'hope', :emendation_type => et)
  EmendationRule.create!(:original => 'stanislaus', :replacement => 'stanley', :emendation_type => et)
  EmendationRule.create!(:original => 'stephania', :replacement => 'stephanie', :emendation_type => et)
  EmendationRule.create!(:original => 'stephanus', :replacement => 'stephen', :emendation_type => et)
  EmendationRule.create!(:original => 'suenius', :replacement => 'swain', :emendation_type => et)
  EmendationRule.create!(:original => 'susanna', :replacement => 'susan', :emendation_type => et)
  EmendationRule.create!(:original => 'sybilla', :replacement => 'sybil', :emendation_type => et)
  EmendationRule.create!(:original => 'tancredus', :replacement => 'tancred', :emendation_type => et)
  EmendationRule.create!(:original => 'terentius', :replacement => 'terence', :emendation_type => et)
  EmendationRule.create!(:original => 'theobaldus', :replacement => 'theobald', :emendation_type => et)
  EmendationRule.create!(:original => 'theodoricus', :replacement => 'derek', :emendation_type => et)
  EmendationRule.create!(:original => 'theodorus', :replacement => 'theodore', :emendation_type => et)
  EmendationRule.create!(:original => 'theresia', :replacement => 'theresa', :emendation_type => et)
  EmendationRule.create!(:original => 'timotheus', :replacement => 'timothy', :emendation_type => et)
  EmendationRule.create!(:original => 'tobias', :replacement => 'toby', :emendation_type => et)
  EmendationRule.create!(:original => 'tullius', :replacement => 'tully', :emendation_type => et)
  EmendationRule.create!(:original => 'ulricus', :replacement => 'ulric', :emendation_type => et)
  EmendationRule.create!(:original => 'valentinus', :replacement => 'valentine', :emendation_type => et)
  EmendationRule.create!(:original => 'vergilius', :replacement => 'vergil', :emendation_type => et)
  EmendationRule.create!(:original => 'veritas', :replacement => 'verity', :emendation_type => et)
  EmendationRule.create!(:original => 'victoria', :replacement => 'victory', :emendation_type => et)
  EmendationRule.create!(:original => 'vincentius', :replacement => 'vincent', :emendation_type => et)
  EmendationRule.create!(:original => 'viola', :replacement => 'violet', :emendation_type => et)
  EmendationRule.create!(:original => 'virgilius', :replacement => 'virgil', :emendation_type => et)
  EmendationRule.create!(:original => 'vitus', :replacement => 'guy', :emendation_type => et)
  EmendationRule.create!(:original => 'viviana', :replacement => 'vivian', :emendation_type => et)
  EmendationRule.create!(:original => 'vivianus', :replacement => 'vivian', :emendation_type => et)
  EmendationRule.create!(:original => 'xaverus', :replacement => 'xavier', :emendation_type => et)
  EmendationRule.create!(:original => 'zacharias', :replacement => 'zachary', :emendation_type => et)
end
