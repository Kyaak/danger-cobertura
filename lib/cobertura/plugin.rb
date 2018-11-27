# frozen_string_literal: true

module Danger
  # Show code coverage of modified and added files.
  # Add warnings if minimum file coverage is not achieved.
  #
  # @example Warn on minimum file coverage of 30% and show all modified files coverage.
  #       cobertura.report = "path/to/my/report.xml"
  #       cobertura.warn_if_file_less_than(percentage: 30)
  #       cobertura.show_coverage
  #
  # @see  Kyaak/danger-cobertura
  # @tags cobertura, coverage
  #
  class DangerCobertura < Plugin
    require "oga"
    require_relative "./coverage_item"

    ERROR_FILE_NOT_SET = "Cobertura file not set. Use 'cobertura.file = \"path/to/my/report.xml\"'."
    ERROR_FILE_NOT_FOUND = "No file found at %s"

    # @return [String] Path to the xml formatted cobertura report.
    attr_accessor :report

    # Warn if a modified file has a lower total coverage than defined.
    #
    # @param percentage [Float] The minimum code coverage required for a file.
    # @return [Array<String>] Warnings of files with a lower coverage.
    def warn_if_file_less_than(percentage:)
      filtered_items.each do |item|
        next unless item.total_percentage < percentage

        warn "#{item.name} has less than #{percentage}% coverage"
      end
    end

    # Show markdown table of modified and added files.
    #
    # @return [Array<String>] A markdown report of modified files and their coverage report.
    def show_coverage
      return if filtered_items.empty?

      line = +"## Code coverage\n"
      line << "File | Coverage\n"
      line << "-----|-----\n"
      filtered_items.each do |item|
        line << "#{item.name} | #{format('%.2f', item.total_percentage)}\n"
      end
      markdown line
    end

    private

    # Getter for coverage items of targeted files.
    # Only coverage items contained in the targeted files list will be returned.
    #
    # @return [Array<CoverageItem>] Filtered array of items
    def filtered_items
      @filtered_items ||= coverage_items.select do |item|
        target_files.include? item.file_name
      end
    end

    # A getter for current modified and added files.
    #
    # @return [Danger::FileList] Wrapper FileList object.
    def target_files
      @target_files ||= git.modified_files + git.added_files
    end

    # Parse the defined coverage report file.
    #
    # @return [Oga::XML::Document] The root xml object.
    def parse
      raise ERROR_FILE_NOT_SET if report.nil? || report.empty?
      raise format(ERROR_FILE_NOT_FOUND, report) unless File.exist?(report)

      Oga.parse_xml(File.read(report))
    end

    # Convenient method to not always parse the report but keep it in the memory.
    #
    # @return [Oga::XML::Document] The root xml object.
    def xml_report
      @xml_report ||= parse
    end

    # Extract and create all class items from the xml report.
    #
    # @return [Array<CoverageItem>] Items with cobertura class information.
    def coverage_items
      @coverage_items ||= xml_report.xpath("//class").map do |node|
        CoverageItem.new(node)
      end
    end
  end
end
