require_relative "../../config/environment"
require_relative "../../lib/new_freereg_csv_update_processor"

RSpec.describe FreeregValidations do
  describe ".valid_ucf_expression?" do
    it "accepts valid UCF expressions" do
      valid_expressions = [
        "_",
        "__",
        "A_B",
        "[ht]",
        "[C_]",
        "F{1,2}[EI]RKIN",
        "[H_]AT{0,1}ER",
        "F_{1,2}ERKIN",
        "_{0,1}",
        "F{1,}ERKIN",
        "A * B",
        "RACHARD?",
        "BULCOCK (notes)",
        "(abc)",
        "(123)",
        "(abc123)"
      ]

      expect(valid_expressions).to all(satisfy { |value| described_class.valid_ucf_expression?(value) })
    end

    it "rejects malformed delimiters, brackets, braces, and operators" do
      invalid_expressions = [
        "[I_[N*",
        "?[",
        "DAN(C}ER",
        "D[AU_[NN",
        "BULCOCK?)",
        "MERYG[A_TE",
        "AMOS[]",
        "SM[123]ITH",
        "SM{123}ITH",
        "{1,2}GATE",
        "{123}GATE",
        "F{,2}ERKIN",
        "F{1,2,3}ERKIN",
        "SM_{a,3}TH",
        "AM_{}S",
        "BENNE[T_}T",
        "M*[C_[TON",
        "HEAL(SY}",
        "[R_[]AU]SHALL",
        "F{2,1}ERKIN",
        "A*_B",
        "A**B",
        "RACHARD??",
        "?RACHARD",
        "RACH?ARD"
      ]

      expect(invalid_expressions).to all(satisfy { |value| !described_class.valid_ucf_expression?(value) })
    end

    it "rejects unmatched and nested parentheses" do
      invalid_parentheses = ["BULCOCK)", "BULCOCK (", "NAME (outer (inner))"]

      expect(invalid_parentheses).to all(satisfy { |value| !described_class.valid_parenthesis_expression?(value) })
    end

    it "rejects empty or whitespace-only parenthetical groups" do
      empty_groups = ["()", "( )", "(  )", "(    )", "ER(   )S"]

      expect(empty_groups).to all(satisfy { |value| !described_class.valid_parenthesis_expression?(value) })
    end
  end

  describe "CSV name-field validation" do
    let(:csv_file) { CsvFile.allocate }

    it "reports malformed parenthetical groups with the parenthesis error" do
      ["()", "( )", "(  )", "(    )", "BULCOCK)"].each do |value|
        expect(csv_file.validate_ucf_fields_for_record(forename: value))
          .to eq("Invalid parenthesis expression in forename: #{value}")
      end
    end

    it "reports malformed UCF values with the UCF error" do
      ["[G", "AMOS[]", "SM{123}ITH", "{1,2}GATE"].each do |value|
        expect(csv_file.validate_ucf_fields_for_record(forename: value))
          .to eq("Invalid UCF expression in forename: #{value}")
      end
    end

    it "checks each forename and surname field while ignoring non-name fields" do
      expect(csv_file.validate_ucf_fields_for_record(
        father_forename: "John",
        mother_surname: "SM[123]ITH",
        baptism_date: "1 Jan ("
      )).to eq("Invalid UCF expression in mother_surname: SM[123]ITH")
    end

    it "does not validate date fields as name fields" do
      expect(csv_file.validate_ucf_fields_for_record(baptism_date: "1 Jan ("))
        .to be_nil
    end
  end
end
