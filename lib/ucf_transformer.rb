# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module UcfTransformer

  BRACE_REGEX = /(\[(\w*?)\])/
  EDITORIAL_NOT_UCF = /blank|sic|illegible|\?|unnamed|deceased|wife|son|daughter|widow/
  TENTATIVE_NAME_NOT_UCF = /(\[(john|william|thomas|james|mary|richard)\])/
  QUESTION_MARK_UCF = /(\w*?)\?/

  def self.expand_single_name(name)
    # seed the expansions with the untransformed name
    expanded_names = [name]
    # loop through each UCF expression
    name.scan(BRACE_REGEX).each do |(replacement, contents)|
      new_expansions = []
      unless contents =~ EDITORIAL_NOT_UCF
        # loop through each character in the UCF expression
        contents.each_char do |character|
          # add the permutation to the expansion
          expanded_names.each do |forename|
            new_name = forename.sub(replacement, character)
            new_expansions << new_name
          end
        end
      end
      expanded_names = new_expansions
    end

    # p name
    # p expanded_names
    if expanded_names == [name]
      nil
    else
      expanded_names
    end
  end

  def self.transform(name_array)
    transformed_names = []
    # loop through each name
    name_array.each do |name|
      # first, handle the names in square brackets (invalid but common)
      if name.first_name
        name.first_name.sub!(TENTATIVE_NAME_NOT_UCF,'\2')
        name.first_name.sub!(QUESTION_MARK_UCF, '\1')

        expanded_forenames = expand_single_name(name.first_name)
        if expanded_forenames # only add the transformation if we did stuff
          transformed_names = expanded_forenames.map { |forename| SearchName.new(name.attributes.merge({:first_name => forename, :origin => 'ucf'}))}
        end
      end

      if name.last_name
        name.last_name.sub!(TENTATIVE_NAME_NOT_UCF,'\2')
        name.last_name.sub!(QUESTION_MARK_UCF,'\1')
        expanded_surnames = expand_single_name(name.last_name)
        if expanded_surnames # only add the transformation if we did stuff
          transformed_names += expanded_surnames.map { |surname| SearchName.new(name.attributes.merge({:last_name => surname, :origin => 'ucf'}))}
        end
      end
    end
    name_array + transformed_names
  end

  # Detect if a string contains any wildcard UCF characters
  def self.contains_wildcard_ucf?(name_part)
    # Early return if blank
    if name_part.blank?
      Rails.logger.debug "[UCF Check] Received blank input"
      return false
    end

    # Define the set of wildcard UCF characters
    wildcard_chars = ['*', '_', '?', '{', '}']

    # Build a regex that matches any of them
    regex = Regexp.union(wildcard_chars)

    # Perform the match
    flagged = name_part.match?(regex)

    # Debugging output
    Rails.logger.info "[UCF Check] Scanning string: #{name_part.inspect}"
    Rails.logger.debug "[UCF Check] Wildcard characters: #{wildcard_chars.join(' ')}"
    Rails.logger.debug "[UCF Check] Regex built: #{regex.inspect}"
    Rails.logger.debug "[UCF Check] Flagged? #{flagged}"

    flagged
  end

  # def self.ucf_to_regex(name_part)
  #   transformed =
  #      name_part
  #       .gsub(/\./, '\.')              # escape literal dots
  #       .gsub(/_\{(\d+,\d+|\d+,\s*|\d+)\}/) { |m|
  #         # Handle underscore + curly brace quantifiers
  #         quantifier = m.match(/_\{(.+)\}/)[1]
  #         "\\w{#{quantifier}}"
  #       }
  #       .gsub(/_/, ".")                # underscore → any single char
  #       .gsub(/\*/, '\w+')             # asterisk → word characters
  #       .gsub(/\[([^\]]+)\]/, '[\1]')  # preserve square bracket groups

  #   begin
  #     Regexp.new(transformed)
  #   rescue RegexpError => e
  #     Rails.logger.warn("[#{Time.current.iso8601}] UCF regex error: #{e.message}")
  #     name_part
  #   end
  # end

  def self.ucf_to_regex(name_part)
    return name_part if name_part.blank?
    
    # 1. Escape literal dots: "Dr.J*" -> "Dr\.J*"
    # This prevents the dot from matching "any character" in Regex.
    regex_string = name_part.gsub('.', '\.')

    # 2a. Handle underscore + range wildcards: "Den_{1,2}is" -> "Den.{1,2}is"
    # UCF ranges with underscore mean "any sequence of length n to m", which in Regex is ".{n,m}".
    regex_string = regex_string.gsub(/_\{(\d*,?\d*)\}/, '.{\1}')

    # 2b. Bare quantifiers are left unchanged: "Den{1,2}is" stays as "Den{1,2}is"
    # In standard regex, {m,n} applies to the preceding character/group (the 'n' repeats m-n times).
    # No substitution needed for bare quantifiers.

    # 3. Convert single character wildcards: "Sm_th" -> "Sm.th"
    # UCF "_" matches exactly one character, which in Regex is ".".
    regex_string = regex_string.gsub('_', '.')

    # 4. Convert multi-character wildcards: "Jo*" -> "Jo\w+"
    # UCF "*" matches one or more word characters, which in Regex is "\w+".
    regex_string = regex_string.gsub('*', '\w+')

    begin
      # Detect unclosed quantifiers
      if regex_string =~ /\{\d+(?:,\d+)?$/
        raise RegexpError, "Unclosed quantifier"
      end

      # Add anchors to enforce exact full-string matching (not substring matching)
      anchored_pattern = "^#{regex_string}$"

      # Attempt to create a new Regular Expression object with case-insensitive matching.
      ::Regexp.new(anchored_pattern, Regexp::IGNORECASE)
    rescue RegexpError => e
      # If the resulting pattern is invalid Regex (e.g. mismatched brackets),
      # log a warning and return the original string so the application doesn't crash.
      Rails.logger.warn("UCF to Regex conversion failed for '#{name_part}': #{e.message}")
      name_part
    end
  end 

  def self.wildcard_ucf_to_regex(name_part)
  end
end
