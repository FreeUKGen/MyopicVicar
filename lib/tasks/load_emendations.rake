desc "Initialize the emendation rules"

# for original 'wm', add_ruleset will add rules for 'wm', 'wm.', 'wm:', and 'wm-'
def add_ruleset(parms)
  orig = parms[:original]
  EmendationRule.create!(parms) unless orig==parms[:replacement]
  parms[:original] = orig+'.'
  EmendationRule.create!(parms)
  parms[:original] = orig+':'
  EmendationRule.create!(parms)
  parms[:original] = orig+'-'
  EmendationRule.create!(parms)
end

task :load_emendations => :environment do
  THIS_RAKE_TASK = 'load_emendations rake task'
  ets = EmendationType.where(:origin => THIS_RAKE_TASK)
  ets.each do |et|
    et.emendation_rules.delete_all
    et.delete
  end
  #if :gender is specified, the emendation rule is only applied to people with that gender. Applies to both if :gender is nil.
  et = EmendationType.create!(:name => 'expansion', :target_field => :first_name, :origin => THIS_RAKE_TASK)
  add_ruleset(:original => 'abig', :replacement => 'abigail', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'abm', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  add_ruleset(:original => 'abra', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  add_ruleset(:original => 'abrah', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  add_ruleset(:original => 'abraha', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  add_ruleset(:original => 'abrahm', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  add_ruleset(:original => 'abram', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  add_ruleset(:original => 'abrm', :replacement => 'abraham', :emendation_type => et, :gender => 'm') #
  add_ruleset(:original => 'abr', :replacement => 'abraham', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'agn', :replacement => 'agnes', :emendation_type => et)
  add_ruleset(:original => 'alex', :replacement => 'alexander', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'alex', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'alexand', :replacement => 'alexander', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'alexand', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'alexandr', :replacement => 'alexander', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'alexandr', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'alexdr', :replacement => 'alexander', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'alexdr', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'alexr', :replacement => 'alexander', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'alexr', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'alf', :replacement => 'alfred', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'alfd', :replacement => 'alfred', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'alic', :replacement => 'alice', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'allex', :replacement => 'alexander', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'allex', :replacement => 'alexandra', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'amb', :replacement => 'ambrose', :emendation_type => et)
  add_ruleset(:original => 'and', :replacement => 'andrew', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'andr', :replacement => 'andrew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'andw', :replacement => 'andrew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'ant', :replacement => 'anthony', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'anth', :replacement => 'anthony', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'antho', :replacement => 'anthony', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'anthy', :replacement => 'anthony', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'anto', :replacement => 'anthony', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'anty', :replacement => 'anthony', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'arch', :replacement => 'archibald', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'archd', :replacement => 'archibald', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'art', :replacement => 'arthur', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'arth', :replacement => 'arthur', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'atha', :replacement => 'agatha', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'aug', :replacement => 'augustus', :emendation_type => et)
  add_ruleset(:original => 'barb', :replacement => 'barbara', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'barba', :replacement => 'barbara', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'bart', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'barth', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'bartho', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'barthol', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'barthw', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'barw', :replacement => 'bartholomew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'ben', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'benj', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'benja', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'benjam', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'benjamn', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'benjan', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'benjm', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'benj:n', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'benjn', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'benn', :replacement => 'benjamin', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'brid', :replacement => 'bridget', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'bridgt', :replacement => 'bridget', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'cath', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#sdx
  add_ruleset(:original => 'cath', :replacement => 'catherine', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'catha', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'cathar', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'cathe', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'cather', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'cathn', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#sdx
  add_ruleset(:original => 'cathn', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'cathne', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#sdx
  add_ruleset(:original => 'cathne', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'cathr', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#sdx
  add_ruleset(:original => 'cathr', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'cathrn', :replacement => 'catharine', :emendation_type => et, :gender => 'f')#sdx
  add_ruleset(:original => 'cathrn', :replacement => 'catherine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'cha', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'char', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'charl', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'charls', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'chars', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'chas', :replacement => 'charles', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'chr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'chris', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'chrisr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'christ', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christ:n', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christ:n', :replacement => 'christian', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christia-', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'christia-', :replacement => 'christian', :emendation_type => et)##sdx same female
  EmendationRule.create!(:original => 'christn', :replacement => 'christopher', :emendation_type => et, :gender => 'm')##
  EmendationRule.create!(:original => 'christn.', :replacement => 'christian', :emendation_type => et, :gender => 'm')##
  EmendationRule.create!(:original => 'christn.', :replacement => 'christopher', :emendation_type => et, :gender => 'm')##
  add_ruleset(:original => 'christo', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'christop', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'christoph', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'christophr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'christopr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'christr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'chro', :replacement => 'christopher', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'chrs', :replacement => 'charles', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'clem', :replacement => 'clement', :emendation_type => et)
  add_ruleset(:original => 'clemt', :replacement => 'clement', :emendation_type => et)#
  add_ruleset(:original => 'const', :replacement => 'constance', :emendation_type => et)
  add_ruleset(:original => 'corn', :replacement => 'cornelius', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'cuth', :replacement => 'cuthbert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'cuthbt', :replacement => 'cuthbert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'cutht', :replacement => 'cuthbert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'dan', :replacement => 'daniel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'danl', :replacement => 'daniel', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'danll', :replacement => 'daniel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'dav', :replacement => 'david', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'davd', :replacement => 'david', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'deb', :replacement => 'deborah', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'den', :replacement => 'dennis', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'dick', :replacement => 'richard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'don', :replacement => 'donald', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'dond', :replacement => 'donald', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'dor', :replacement => 'dorothy', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'doro', :replacement => 'dorothy', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'doroth', :replacement => 'dorothy', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'dory', :replacement => 'dorothy', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'doug', :replacement => 'douglas', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'dugal', :replacement => 'dugald', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'dy', :replacement => 'dorothy', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'ed', :replacement => 'edmund', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'ed', :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'eda', :replacement => 'edith', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'edi', :replacement => 'edith', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'edi', :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'edd', :replacement => 'edmund', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'edd', :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'edm', :replacement => 'edmund', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'edmd', :replacement => 'edmund', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'edm:d', :replacement => 'edmund', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'edrus', :replacement => 'edward', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'edw', :replacement => 'edward', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => "edw'd", :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "edw:d", :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'edwd', :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'edwrd', :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'eleanr', :replacement => 'eleanor', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elear', :replacement => 'eleanor', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'eli', :replacement => 'elias', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'eli', :replacement => 'elijah', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'elis', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elisa', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elisab', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elisabth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elisath', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elis:th', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elish', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elisth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elith', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elisath', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elisath', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elisath', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'eliz', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => "eliz'h", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => "eliz-th", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "eliz:th", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "eliz'b", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "eliz'h", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "eliz'th", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'eliza', :replacement => 'eliza', :emendation_type => et, :gender => 'f')#for punctuation at end
  add_ruleset(:original => 'eliza', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizab', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizabeth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#for punctuation at end
  add_ruleset(:original => 'elizabh', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizabth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizae', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizah', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizath', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizb', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizbeth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizbt', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizbth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizh', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizt', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'elizth', :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "elliz", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "ellizab", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "elsab", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "elsp", :replacement => 'elspeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "elyz", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "elyzab", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "elz", :replacement => 'eliza', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "elz", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "elzab", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "elzth", :replacement => 'elizabeth', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "em", :replacement => 'emma', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "em", :replacement => 'emily', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "emly", :replacement => 'emily', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "emm", :replacement => 'emma', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "emm", :replacement => 'emily', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'esth', :replacement => 'esther', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'ezek', :replacement => 'ezekiel', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => "ewd", :replacement => 'edward', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "florrie", :replacement => 'florence', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "fra", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "fra", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "fran", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "fran", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "franc", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "franc", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "franc", :replacement => 'franchesca', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "francs", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "francs", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "francs", :replacement => 'franchesca', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "frans", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "frans", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "frans", :replacement => 'franchesca', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "fras", :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "fras", :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "fras", :replacement => 'franchesca', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'fred', :replacement => 'frederick', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'frederic', :replacement => 'frederick', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "fred'k", :replacement => 'frederick', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'fredk', :replacement => 'frederick', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'froo', :replacement => 'franco', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'fs', :replacement => 'francis', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'fs', :replacement => 'frances', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'gab', :replacement => 'gabriel', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'gab', :replacement => 'gabrielle', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'gab', :replacement => 'gabriella', :emendation_type => et, :gender => 'f')#sdx
  add_ruleset(:original => 'geo', :replacement => 'george', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'geo', :replacement => 'georgiana', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'geoe', :replacement => 'george', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'geor', :replacement => 'george', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'georg', :replacement => 'george', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'geof', :replacement => 'geoffrey', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'gertie', :replacement => 'gertrude', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'gerty', :replacement => 'gertrude', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'gilb', :replacement => 'gilbert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'gilbt', :replacement => 'gilbert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'godf', :replacement => 'godfrey', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'gr', :replacement => 'griffith', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'greg', :replacement => 'gregory', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'griffth', :replacement => 'griffith', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'guil', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'guil', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'guilieli', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'guilieli', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'gul', :replacement => 'william', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'gul', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'guli', :replacement => 'william', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'guli', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'guliel', :replacement => 'william', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'guliel', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'gulielm', :replacement => 'william', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'gulielm', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'gulielmi', :replacement => 'william', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'gulielmi', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'gull', :replacement => 'william', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'gull', :replacement => 'gulielmus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'han', :replacement => 'hannah', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'hanh', :replacement => 'hannah', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'hann', :replacement => 'hannah', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'hannh', :replacement => 'hannah', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'hel', :replacement => 'helen', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'hen', :replacement => 'henry', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'henery', :replacement => 'henry', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'henr', :replacement => 'henry', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'henric', :replacement => 'henrici', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'henric', :replacement => 'henry', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'henrici', :replacement => 'henry', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'heny', :replacement => 'henry', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'herb', :replacement => 'herbert', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'hon', :replacement => 'honorable', :emendation_type => et)#
  add_ruleset(:original => 'honble', :replacement => 'honorable', :emendation_type => et)#
  add_ruleset(:original => 'honr', :replacement => 'honorable', :emendation_type => et)#
  add_ruleset(:original => 'hump', :replacement => 'humphrey', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'humph', :replacement => 'humphrey', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'humphr', :replacement => 'humphrey', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'humpy', :replacement => 'humphrey', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'hy', :replacement => 'henry', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'illeg', :replacement => 'illegitimus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'ioh', :replacement => 'john', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'isa', :replacement => 'isaiah', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'isa', :replacement => 'isabel', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'isa', :replacement => 'isabella', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'isab', :replacement => 'isabel', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'isab', :replacement => 'isabella', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'isaba', :replacement => 'isabel', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'isaba', :replacement => 'isabella', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'isb', :replacement => 'isabel', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'isob', :replacement => 'isabel', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'isob', :replacement => 'isabella', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'jabus', :replacement => 'james', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'jac', :replacement => 'james', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'jacob', :replacement => 'jacob', :emendation_type => et, :gender => 'm')#for punctiuation at end
  add_ruleset(:original => 'jane', :replacement => 'jane', :emendation_type => et, :gender => 'f')#for punctiuation at end
  add_ruleset(:original => 'jant', :replacement => 'janet', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'jas', :replacement => 'james', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'jeff', :replacement => 'jeffery', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'jer', :replacement => 'jeremiah', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'jer', :replacement => 'jeremy', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jere', :replacement => 'jeremy', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jere', :replacement => 'jeremiah', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jerem', :replacement => 'jeremy', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jerem', :replacement => 'jeremiah', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jeremh', :replacement => 'jeremy', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jeremh', :replacement => 'jeremiah', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jerh', :replacement => 'jeremy', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jerh', :replacement => 'jeremiah', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jhn', :replacement => 'john', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jho', :replacement => 'john', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jn', :replacement => 'john', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jn', :replacement => 'junior', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => 'jn:o', :replacement => 'john', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jno', :replacement => 'john', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'jnr', :replacement => 'junior', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jo', :replacement => 'john', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'joe', :replacement => 'joseph', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'joh', :replacement => 'john', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'joh', :replacement => 'johannes', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'joha', :replacement => 'johanna', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'johan', :replacement => 'johanna', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'johan', :replacement => 'johannes', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'johanes', :replacement => 'johannes', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'johanis', :replacement => 'johannis', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'johes', :replacement => 'johannes', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'johis', :replacement => 'johannis', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'john', :replacement => 'john', :emendation_type => et, :gender => 'm')#for punctuation at end
  add_ruleset(:original => 'johnes', :replacement => 'johannes', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jon', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'jona', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jonan', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jonat', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jonath', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jonathn', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jonn', :replacement => 'jonathan', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jos', :replacement => 'joseph', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'josa', :replacement => 'joshua', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'josh', :replacement => 'joshua', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'josh', :replacement => 'josiah', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'josp', :replacement => 'joseph', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'josph', :replacement => 'joseph', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jr', :replacement => 'junior', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jsp', :replacement => 'joseph', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jud', :replacement => 'judith', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'jud', :replacement => 'judas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'jun', :replacement => 'junior', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'junr', :replacement => 'junior', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'kat', :replacement => 'katherine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'kat', :replacement => 'katharine', :emendation_type => et, :gender => 'f')#sdx
  add_ruleset(:original => 'kath', :replacement => 'katherine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'kath', :replacement => 'katharine', :emendation_type => et, :gender => 'f')#sdx
  add_ruleset(:original => 'kathar', :replacement => 'katharine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'kather', :replacement => 'katherine', :emendation_type => et, :gender => 'f')#sdx
  add_ruleset(:original => 'kathr', :replacement => 'katherine', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'kathr', :replacement => 'katharine', :emendation_type => et, :gender => 'f')#sdx
  add_ruleset(:original => 'lanc', :replacement => 'lancelot', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'lau', :replacement => 'laurence', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'laur', :replacement => 'laurence', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'law', :replacement => 'lawrence', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'lawr', :replacement => 'lawrence', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'leo', :replacement => 'leonard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'leon', :replacement => 'leonard', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'leond', :replacement => 'leonard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'lottie', :replacement => 'charlotte', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'lyd', :replacement => 'lydia', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'mag', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'maggie', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'mags', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'magt', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'mar', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'mar', :replacement => 'mary', :emendation_type => et, :gender => 'f')##
  add_ruleset(:original => 'marg', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "marg't", :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  EmendationRule.create!(:original => "marg:t", :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'marga', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'margar', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'margart', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'margat', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'marget', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'margr', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'margrt', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'margt', :replacement => 'margaret', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'margtt', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'marj', :replacement => 'marjory', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'marmad', :replacement => 'marmaduke', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'mart', :replacement => 'martin', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'mart', :replacement => 'martha', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'marth', :replacement => 'martha', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'mary', :replacement => 'mary', :emendation_type => et, :gender => 'f')#for punctuation at end
  add_ruleset(:original => 'mary-ann', :replacement => 'mary', :emendation_type => et, :gender => 'f')#exp?
  add_ruleset(:original => 'mary-ann', :replacement => 'ann', :emendation_type => et, :gender => 'f')#exp?
  add_ruleset(:original => 'mary-anne', :replacement => 'mary', :emendation_type => et, :gender => 'f')#exp?
  add_ruleset(:original => 'mary-anne', :replacement => 'ann', :emendation_type => et, :gender => 'f')#exp?
  add_ruleset(:original => 'mat', :replacement => 'matthew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'math', :replacement => 'matthias', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'math', :replacement => 'matthew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'mathw', :replacement => 'matthew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'mathew', :replacement => 'matthew', :emendation_type => et, :gender => 'm')#sdx
  add_ruleset(:original => 'matt', :replacement => 'matthew', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'matt', :replacement => 'matthias', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'matth', :replacement => 'matthew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'matth', :replacement => 'matthias', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'matthw', :replacement => 'matthew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'mattw', :replacement => 'matthew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'matw', :replacement => 'matthew', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'mau', :replacement => 'maurice', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'mgt', :replacement => 'margaret', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'mic', :replacement => 'michael', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'mich', :replacement => 'michael', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'michl', :replacement => 'michael', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'micls', :replacement => 'michael', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'mill', :replacement => 'millicent', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'mry', :replacement => 'mary', :emendation_type => et, :gender => 'f')##
  add_ruleset(:original => 'my', :replacement => 'mary', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'nat', :replacement => 'nathan', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nat', :replacement => 'nathaniel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nath', :replacement => 'nathan', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nath', :replacement => 'nathaniel', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'nathal', :replacement => 'nathaniel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nathan', :replacement => 'nathaniel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "nathan'l", :replacement => 'nathaniel', :emendation_type => et, :gender => 'm')###
  add_ruleset(:original => 'nathanl', :replacement => 'nathaniel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nathl', :replacement => 'nathaniel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nathll', :replacement => 'nathaniel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nic', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nich', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'nichi', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nichls', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nicho', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nichol', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nichos', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nichs', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nick', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nico', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'nics', :replacement => 'nicholas', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'ol', :replacement => 'oliver', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'pat', :replacement => 'patricia', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'pat', :replacement => 'patrick', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'patr', :replacement => 'patricia', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'patr', :replacement => 'patrick', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'pen', :replacement => 'penelope', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'pet', :replacement => 'peter', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'petr', :replacement => 'peter', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'ph', :replacement => 'philip', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'phil', :replacement => 'philip', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'phill', :replacement => 'philip', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'philp', :replacement => 'philip', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'phin', :replacement => 'phineas', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'phyl', :replacement => 'phyllis', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'prisc', :replacement => 'priscilla', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'pru', :replacement => 'prudence', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'rach', :replacement => 'rachel', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'rand', :replacement => 'randall', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'rand', :replacement => 'randolph', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'randl', :replacement => 'randall', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'randl', :replacement => 'randolph', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'ray', :replacement => 'raymond', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'rbt', :replacement => 'robert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'reb', :replacement => 'rebecca', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'rebec', :replacement => 'rebecca', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'reg', :replacement => 'reginald', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'ric', :replacement => 'richard', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'ricd', :replacement => 'richard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'rich', :replacement => 'richard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'rich:d', :replacement => 'richard', :emendation_type => et, :gender => 'm')###
  add_ruleset(:original => 'rich.d', :replacement => 'richard', :emendation_type => et, :gender => 'm')###
  add_ruleset(:original => "rich'd", :replacement => 'richard', :emendation_type => et, :gender => 'm')###
  add_ruleset(:original => 'richa', :replacement => 'richard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'richd', :replacement => 'richard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'richi', :replacement => 'richard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'richdus', :replacement => 'richard', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'richus', :replacement => 'ricardus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'richus', :replacement => 'richard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'ricus', :replacement => 'ricardus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'ricus', :replacement => 'richard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'rid', :replacement => 'richard', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'rob', :replacement => 'robert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'rob:t', :replacement => 'robert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "rob't", :replacement => 'robert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'rob.t', :replacement => 'robert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'robt', :replacement => 'robert', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'robte', :replacement => 'robert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'robti', :replacement => 'robert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'robtus', :replacement => 'robert', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'robtus', :replacement => 'robertus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'rodk', :replacement => 'roderick', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'rog', :replacement => 'roger', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'rogr', :replacement => 'roger', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'rose-mary', :replacement => 'rose', :emendation_type => et, :gender => 'f')#exp?
  add_ruleset(:original => 'rose-mary', :replacement => 'mary', :emendation_type => et, :gender => 'f')#exp?
  add_ruleset(:original => 'sam', :replacement => 'samuel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'sam', :replacement => 'samantha', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => "sam'l", :replacement => 'samuel', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "sam:l", :replacement => 'samuel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'saml', :replacement => 'samuel', :emendation_type => et, :gender => 'm')
  EmendationRule.create!(:original => "sam:ll", :replacement => 'samuel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'samll', :replacement => 'samuel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'samu', :replacement => 'samuel', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'sar', :replacement => 'sarah', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'sara', :replacement => 'sara', :emendation_type => et, :gender => 'f')#for punctuation at end
  add_ruleset(:original => 'sarah', :replacement => 'sarah', :emendation_type => et, :gender => 'f')#for punctuation at end
  add_ruleset(:original => 'sarah-ann', :replacement => 'ann', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'sarah-ann', :replacement => 'sarah', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'sarh', :replacement => 'sarah', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'silv', :replacement => 'sylvester', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'sim', :replacement => 'simon', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'sol', :replacement => 'solomon', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'ste', :replacement => 'stephen', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'step', :replacement => 'stephen', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'steph', :replacement => 'stephen', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'stephn', :replacement => 'stephen', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'stepn', :replacement => 'stephen', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'sus', :replacement => 'susan', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'susan', :replacement => 'susanna', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'susna', :replacement => 'susanna', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'susanh', :replacement => 'susannah', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'theo', :replacement => 'theodore', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'tho', :replacement => 'thomas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'tho:s', :replacement => 'thomas', :emendation_type => et, :gender => 'm')###
  add_ruleset(:original => "tho's", :replacement => 'thomas', :emendation_type => et, :gender => 'm')###
  add_ruleset(:original => 'thom', :replacement => 'thomas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'thoma', :replacement => 'thomas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "thom's", :replacement => 'thomas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'thomas', :replacement => 'thomas', :emendation_type => et, :gender => 'm')#for punctuation at end
  add_ruleset(:original => 'thoms', :replacement => 'thomas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'thos', :replacement => 'thomas', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'tim', :replacement => 'timothy', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'timo', :replacement => 'timothy', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'timy', :replacement => 'timothy', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'tom', :replacement => 'thomas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'tos', :replacement => 'thomas', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'urs', :replacement => 'ursula', :emendation_type => et, :gender => 'f')
  add_ruleset(:original => 'val', :replacement => 'valentine', :emendation_type => et)
  add_ruleset(:original => 'vinc', :replacement => 'vincent', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'walt', :replacement => 'walter', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'waltr', :replacement => 'walter', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'win', :replacement => 'winifred', :emendation_type => et)
  add_ruleset(:original => 'wil', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'will', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "willa-", :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willi', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "will'm", :replacement => 'william', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "will:m", :replacement => 'william', :emendation_type => et, :gender => 'm')#
  EmendationRule.create!(:original => "will-m", :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willia', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willia', :replacement => 'williamina', :emendation_type => et, :gender => 'f')#
  add_ruleset(:original => 'william', :replacement => 'william', :emendation_type => et, :gender => 'm')#for punctuation at end
  add_ruleset(:original => 'willie', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willim', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willimi', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willimi', :replacement => 'willimus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'williamus', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willimus', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willius', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willius', :replacement => 'willimus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willm', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willmi', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willms', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willms', :replacement => 'willimus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willmus', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willmus', :replacement => 'willimus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wills', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wills', :replacement => 'willimus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'willym', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wilm', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wim', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wllm', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wlm', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wm', :replacement => 'william', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'wmi', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wmus', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wmus', :replacement => 'willimus', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'w:m', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => "w'm", :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wyll', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'wyllm', :replacement => 'william', :emendation_type => et, :gender => 'm')#
  add_ruleset(:original => 'xpr', :replacement => 'christopher', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'xtianus', :replacement => 'christian', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'xtopherus', :replacement => 'christopher', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'zach', :replacement => 'zachariah', :emendation_type => et, :gender => 'm')
  add_ruleset(:original => 'zach', :replacement => 'zacharius', :emendation_type => et, :gender => 'm')

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
  EmendationRule.create!(:original => 'isaak', :replacement => 'isaac', :emendation_type => et)
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
