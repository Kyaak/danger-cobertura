# frozen_string_literal: true

require File.expand_path("spec_helper", __dir__)

module Danger
  describe Danger::DangerCobertura do
    it "should be a plugin" do
      expect(Danger::DangerCobertura.new(nil)).to be_a Danger::Plugin
    end

    SUB_ONE = %w(sub_folder/sub_one.py).freeze
    SUB_TWO = %w(sub_folder/sub_two.py).freeze
    SUB_THREE = %w(sub_folder/sub_three.py).freeze
    SUB_TWO_WARNING = "sub_two.py has less than 90.0% coverage".freeze
    PREFIX = "my_prefix_dir".freeze
    PREFIX_TWO = %w(my_prefix_dir/sub_folder/sub_two.py).freeze

    describe "with Dangerfile" do
      before do
        @dangerfile = testing_dangerfile
        @my_plugin = @dangerfile.cobertura
        @my_plugin.report = "#{File.dirname(__FILE__)}/assets/coverage.xml"
        @dangerfile.git.stubs(:modified_files).returns([])
        @dangerfile.git.stubs(:added_files).returns([])
      end

      it "test" do
        @dangerfile.git.stubs(:modified_files).returns(["Filmustage.DataApi/Filmustage.DataApi/DataAccess/Location.cs"])
        @my_plugin.filename_prefix = "/Users/Martin/Desktop/filmustage-dataapi"
        @my_plugin.show_coverage
      end

      describe "warn_if_file_less_than" do
        it "raises error if file attribute is nil" do
          @my_plugin.report = nil
          expect do
            @my_plugin.warn_if_file_less_than(percentage: 50.0)
          end.to raise_error(DangerCobertura::ERROR_FILE_NOT_SET)
        end

        it "raises error if file attribute is empty" do
          @my_plugin.report = ""
          expect do
            @my_plugin.warn_if_file_less_than(percentage: 50.0)
          end.to raise_error(DangerCobertura::ERROR_FILE_NOT_SET)
        end

        it "raises error if file is not found" do
          @my_plugin.report = "cant/find/my/file.xml"
          expect do
            @my_plugin.warn_if_file_less_than(percentage: 50.0)
          end.to raise_error(/#{@my_plugin.report}/)
        end

        it "adds warn if total coverage lower than given" do
          @dangerfile.git.stubs(:modified_files).returns(%w(sub_folder/sub_two.py top_level_one.py))
          @my_plugin.warn_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:warnings]).to include(SUB_TWO_WARNING)
          expect(@dangerfile.status_report[:warnings]).not_to include("top_level_one.py has less than 90.0% coverage")
        end

        it "does not add warn if coverage not" do
          @dangerfile.git.stubs(:modified_files).returns(SUB_TWO)
          @my_plugin.warn_if_file_less_than(percentage: 10.0)

          expect(@dangerfile.status_report[:warnings]).to be_empty
        end

        it "adds warn for modified files" do
          @dangerfile.git.stubs(:modified_files).returns(SUB_TWO)
          @my_plugin.warn_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:warnings]).to include(SUB_TWO_WARNING)
        end

        it "adds warn for added files" do
          @dangerfile.git.stubs(:added_files).returns(SUB_TWO)
          @my_plugin.warn_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:warnings]).to include(SUB_TWO_WARNING)
        end

        it "adds warn for added and modified files" do
          @dangerfile.git.stubs(:added_files).returns(SUB_TWO)
          @dangerfile.git.stubs(:modified_files).returns(SUB_ONE)
          @my_plugin.warn_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:warnings]).to include(SUB_TWO_WARNING)
          expect(@dangerfile.status_report[:warnings]).to include("sub_one.py has less than 90.0% coverage")
        end

        it "does not add if filename missing prefix" do
          # sub_folder/sub_two.py in xml
          @dangerfile.git.stubs(:added_files).returns(%w(not_including/sub_folder/sub_two.py))
          expect(@my_plugin.filename_prefix).to be_nil

          @my_plugin.warn_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:warnings]).not_to include(SUB_TWO_WARNING)
        end

        it "does add if issue filename prefix set" do
          @dangerfile.git.stubs(:added_files).returns(PREFIX_TWO)
          @my_plugin.filename_prefix = PREFIX
          @my_plugin.warn_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:warnings]).to include(SUB_TWO_WARNING)
        end

        it "does add if git filename prefix set" do
          @dangerfile.git.stubs(:added_files).returns(SUB_TWO)
          @my_plugin.filename_prefix = PREFIX
          @my_plugin.warn_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:warnings]).to include(SUB_TWO_WARNING)
        end

        it "ignores filename prefix slash" do
          @dangerfile.git.stubs(:added_files).returns(PREFIX_TWO)
          @my_plugin.filename_prefix = "#{PREFIX}/"
          @my_plugin.warn_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:warnings]).to include(SUB_TWO_WARNING)
        end

        it "should not add name with $" do
          @dangerfile.git.stubs(:added_files).returns(SUB_THREE)
          @my_plugin.warn_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:warnings]).to include("sub_three.py has less than 90.0% coverage")
          expect(@dangerfile.status_report[:warnings]).not_to include("sub_three$.py has less than 90.0% coverage")
        end
      end

      describe "show_coverage" do
        it "raises error if file attribute is nil" do
          @my_plugin.report = nil
          expect do
            @my_plugin.show_coverage
          end.to raise_error(DangerCobertura::ERROR_FILE_NOT_SET)
        end

        it "raises error if file attribute is empty" do
          @my_plugin.report = ""
          expect do
            @my_plugin.show_coverage
          end.to raise_error(DangerCobertura::ERROR_FILE_NOT_SET)
        end

        it "raises error if file is not found" do
          @my_plugin.report = "cant/find/my/file.xml"
          expect do
            @my_plugin.show_coverage
          end.to raise_error(/#{@my_plugin.report}/)
        end

        it "adds coverage for modified files" do
          @dangerfile.git.stubs(:modified_files).returns(SUB_TWO)
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns]).not_to be_empty
        end

        it "adds coverage for added files" do
          @dangerfile.git.stubs(:added_files).returns(SUB_TWO)
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns]).not_to be_empty
        end

        it "adds coverage for added and modified files" do
          @dangerfile.git.stubs(:added_files).returns(SUB_TWO)
          @dangerfile.git.stubs(:modified_files).returns(SUB_ONE)
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns]).not_to be_empty
        end

        it "default does not add branch and line" do
          @dangerfile.git.stubs(:modified_files).returns(SUB_THREE)
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns][0].message).to include("File")
          expect(@dangerfile.status_report[:markdowns][0].message).to include("Total")
          expect(@dangerfile.status_report[:markdowns][0].message).to include(table_column_line(2))
          expect(@dangerfile.status_report[:markdowns][0].message).not_to include("Branch")
          expect(@dangerfile.status_report[:markdowns][0].message).not_to include("Line")
          expect(@dangerfile.status_report[:markdowns][0].message).not_to include(table_column_line(4))
          expect(@dangerfile.status_report[:markdowns][0].message).to include("0.00")
        end

        it "additional_header line adds line rate" do
          @dangerfile.git.stubs(:modified_files).returns(SUB_THREE)
          @my_plugin.additional_headers = [:line]
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns][0].message).to include("File")
          expect(@dangerfile.status_report[:markdowns][0].message).to include("Total")
          expect(@dangerfile.status_report[:markdowns][0].message).to include("Line")
          expect(@dangerfile.status_report[:markdowns][0].message).to include(table_column_line(3))
          expect(@dangerfile.status_report[:markdowns][0].message).not_to include("Branch")
          expect(@dangerfile.status_report[:markdowns][0].message).not_to include(table_column_line(4))
          expect(@dangerfile.status_report[:markdowns][0].message).to include("0.00")
        end

        it "additional_header branch adds branch rate" do
          @dangerfile.git.stubs(:modified_files).returns(SUB_THREE)
          @my_plugin.additional_headers = [:branch]
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns][0].message).to include("File")
          expect(@dangerfile.status_report[:markdowns][0].message).to include("Total")
          expect(@dangerfile.status_report[:markdowns][0].message).to include("Branch")
          expect(@dangerfile.status_report[:markdowns][0].message).to include(table_column_line(3))
          expect(@dangerfile.status_report[:markdowns][0].message).not_to include("Line")
          expect(@dangerfile.status_report[:markdowns][0].message).not_to include(table_column_line(4))
          expect(@dangerfile.status_report[:markdowns][0].message).to include("0.00")
        end

        it "additional_header line and branch adds rate" do
          @dangerfile.git.stubs(:modified_files).returns(SUB_THREE)
          @my_plugin.additional_headers = %i(branch line)
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns][0].message).to include("File")
          expect(@dangerfile.status_report[:markdowns][0].message).to include("Total")
          expect(@dangerfile.status_report[:markdowns][0].message).to include("Branch")
          expect(@dangerfile.status_report[:markdowns][0].message).to include("Line")
          expect(@dangerfile.status_report[:markdowns][0].message).to include(table_column_line(4))
          expect(@dangerfile.status_report[:markdowns][0].message).to include("0.00")
        end

        it "does not show coverage if filename prefix missing" do
          @dangerfile.git.stubs(:added_files).returns(%w(not_including/sub_folder/sub_two.py))
          expect(@my_plugin.filename_prefix).to be_nil

          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns]).to be_empty
        end

        it "does show coverage if issue filename prefix matches" do
          @dangerfile.git.stubs(:added_files).returns(PREFIX_TWO)
          @my_plugin.filename_prefix = PREFIX
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns]).not_to be_empty
        end

        it "does show coverage if git filename prefix matches" do
          @dangerfile.git.stubs(:added_files).returns(SUB_TWO)
          @my_plugin.filename_prefix = PREFIX
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns]).not_to be_empty
        end

        it "ignores filename prefix slash" do
          @dangerfile.git.stubs(:added_files).returns(PREFIX_TWO)
          @my_plugin.filename_prefix = "#{PREFIX}/"
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns]).not_to be_empty
        end
      end

      describe "fail_if_file_less_than" do
        it "raises error if file attribute is nil" do
          @my_plugin.report = nil
          expect do
            @my_plugin.fail_if_file_less_than(percentage: 50.0)
          end.to raise_error(DangerCobertura::ERROR_FILE_NOT_SET)
        end

        it "raises error if file attribute is empty" do
          @my_plugin.report = ""
          expect do
            @my_plugin.fail_if_file_less_than(percentage: 50.0)
          end.to raise_error(DangerCobertura::ERROR_FILE_NOT_SET)
        end

        it "raises error if file is not found" do
          @my_plugin.report = "cant/find/my/file.xml"
          expect do
            @my_plugin.fail_if_file_less_than(percentage: 50.0)
          end.to raise_error(/#{@my_plugin.report}/)
        end

        it "adds fail if total coverage lower than given" do
          @dangerfile.git.stubs(:modified_files).returns(%w(sub_folder/sub_two.py top_level_one.py))
          @my_plugin.fail_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:errors]).to include(SUB_TWO_WARNING)
          expect(@dangerfile.status_report[:errors]).not_to include("top_level_one.py has less than 90.0% coverage")
        end

        it "does not add warn if coverage not" do
          @dangerfile.git.stubs(:modified_files).returns(SUB_TWO)
          @my_plugin.fail_if_file_less_than(percentage: 10.0)

          expect(@dangerfile.status_report[:errors]).to be_empty
        end

        it "adds warn for modified files" do
          @dangerfile.git.stubs(:modified_files).returns(SUB_TWO)
          @my_plugin.fail_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:errors]).to include(SUB_TWO_WARNING)
        end

        it "adds warn for added files" do
          @dangerfile.git.stubs(:added_files).returns(SUB_TWO)
          @my_plugin.fail_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:errors]).to include(SUB_TWO_WARNING)
        end

        it "adds warn for added and modified files" do
          @dangerfile.git.stubs(:added_files).returns(SUB_TWO)
          @dangerfile.git.stubs(:modified_files).returns(SUB_ONE)
          @my_plugin.fail_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:errors]).to include(SUB_TWO_WARNING)
          expect(@dangerfile.status_report[:errors]).to include("sub_one.py has less than 90.0% coverage")
        end

        it "does not add if filename missing prefix" do
          # sub_folder/sub_two.py in xml
          @dangerfile.git.stubs(:added_files).returns(%w(not_including/sub_folder/sub_two.py))
          expect(@my_plugin.filename_prefix).to be_nil

          @my_plugin.fail_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:errors]).not_to include(SUB_TWO_WARNING)
        end

        it "does add if issue filename prefix set" do
          @dangerfile.git.stubs(:added_files).returns(PREFIX_TWO)
          @my_plugin.filename_prefix = PREFIX
          @my_plugin.fail_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:errors]).to include(SUB_TWO_WARNING)
        end

        it "does add if git filename prefix set" do
          @dangerfile.git.stubs(:added_files).returns(SUB_TWO)
          @my_plugin.filename_prefix = PREFIX
          @my_plugin.fail_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:errors]).to include(SUB_TWO_WARNING)
        end

        it "ignores filename prefix slash" do
          @dangerfile.git.stubs(:added_files).returns(PREFIX_TWO)
          @my_plugin.filename_prefix = "#{PREFIX}/"
          @my_plugin.fail_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:errors]).to include(SUB_TWO_WARNING)
        end

        it "should not add name with $" do
          @dangerfile.git.stubs(:added_files).returns(SUB_THREE)
          @my_plugin.fail_if_file_less_than(percentage: 90.0)

          expect(@dangerfile.status_report[:errors]).to include("sub_three.py has less than 90.0% coverage")
          expect(@dangerfile.status_report[:errors]).not_to include("sub_three$.py has less than 90.0% coverage")
        end
      end
    end
  end
end
