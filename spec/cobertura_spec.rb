# frozen_string_literal: true

require File.expand_path("spec_helper", __dir__)

module Danger
  describe Danger::DangerCobertura do
    it "should be a plugin" do
      expect(Danger::DangerCobertura.new(nil)).to be_a Danger::Plugin
    end

    describe "with Dangerfile" do
      before do
        @dangerfile = testing_dangerfile
        @my_plugin = @dangerfile.cobertura
        @my_plugin.report = "#{File.dirname(__FILE__)}/assets/coverage.xml"
        @dangerfile.git.stubs(:modified_files).returns([])
        @dangerfile.git.stubs(:added_files).returns([])
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

          expect(@dangerfile.status_report[:warnings]).to include("sub_two.py has less than 90.0% coverage")
          expect(@dangerfile.status_report[:warnings]).not_to include("top_level_one.py has less than 90.0% coverage")
        end

        it "does not add warn if coverage not" do
          @dangerfile.git.stubs(:modified_files).returns(["sub_folder/sub_two.py"])
          @my_plugin.warn_if_file_less_than(percentage: 10.0)

          expect(@dangerfile.status_report[:warnings]).to be_empty
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

        it "prints coverage" do
          @dangerfile.git.stubs(:modified_files).returns(["sub_folder/sub_three.py"])
          @my_plugin.show_coverage

          expect(@dangerfile.status_report[:markdowns][0].message).to include("sub_three.py")
          expect(@dangerfile.status_report[:markdowns][0].message).to include("0.00")
        end
      end
    end
  end
end
