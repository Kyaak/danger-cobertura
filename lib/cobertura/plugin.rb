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

    ERROR_FILE_NOT_SET = "Cobertura file not set. Use 'cobertura.file = \"path/to/my/report.xml\"'.".freeze
    ERROR_FILE_NOT_FOUND = "No file found at %s".freeze
    TABLE_COLUMN_LINE = "-----".freeze

    # Path to the xml formatted cobertura report.
    #
    # @return [String] Report file.
    attr_accessor :report
    # Array of symbols which allows to extend the markdown report columns.
    # Allowed symbols: :branch, :line
    #
    # @return [Array<Symbol>] Columns to add in the markdown report.
    attr_accessor :additional_headers
    # Path prefix to be added to the cobertura class filename attribute.
    #
    # @return [String] Prefix to add to filename path.
    attr_accessor :filename_prefix

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

    # Fail if a modified file has a lower total coverage than defined.
    #
    # @param percentage [Float] The minimum code coverage required for a file.
    # @return [Array<String>] Fail warnings of files with a lower coverage.
    def fail_if_file_less_than(percentage:)
      filtered_items.each do |item|
        next unless item.total_percentage < percentage

        fail "#{item.name} has less than #{percentage}% coverage"
      end
    end

    # Show markdown table of modified and added files.
    # TODO remove * wildcard to accept all parameter: `danger local` bug - https://github.com/danger/danger/issues/1041
    # @return [Array<String>] A markdown report of modified files and their coverage report.
    def show_coverage(*)
      return if filtered_items.empty?

      table = "## Code coverage\n".dup
      table << table_header
      table << table_separation

      filtered_items.each do |item|
        table << table_entry(item)
      end
      markdown table
    end

    private

    # Create the show_coverage column headers.
    #
    # @return [String] Markdown for table headers.
    def table_header
      line = "File|Total".dup
      line << "|Line" if header_line_rate?
      line << "|Branch" if header_branch_rate?
      line << "\n"
    end

    # Create the show_coverage table header separation line.
    #
    # @return [String] Markdown for table header separation.
    def table_separation
      line = "#{TABLE_COLUMN_LINE}|#{TABLE_COLUMN_LINE}".dup
      line << "|#{TABLE_COLUMN_LINE}" if header_line_rate?
      line << "|#{TABLE_COLUMN_LINE}" if header_branch_rate?
      line << "\n"
    end

    # Create the show_coverage table rows.
    #
    # @param item [CoverageItem] Coverage item to put information in the table row.
    # @return [String] Markdown for table rows.
    def table_entry(item)
      line = item.name.dup
      line << "|#{format_coverage(item.total_percentage)}"
      line << "|#{format_coverage(item.line_rate)}" if header_line_rate?
      line << "|#{format_coverage(item.branch_rate)}" if header_branch_rate?
      line << "\n"
    end

    # Check if additional_headers includes symbol :line
    #
    # @return [Boolean] :line header defined.
    def header_line_rate?
      !additional_headers.nil? && additional_headers.include?(:line)
    end

    # Check if additional_headers includes symbol :branch
    #
    # @return [Boolean] :branch header defined.
    def header_branch_rate?
      !additional_headers.nil? && additional_headers.include?(:branch)
    end

    # Format coverage output to two decimals.
    #
    # @param coverage [Float] Value to format.
    # @return [String] Formatted coverage string.
    def format_coverage(coverage)
      format("%.2f", coverage)
    end

    # Getter for coverage items of targeted files.
    # Only coverage items contained in the targeted files list will be returned.
    #
    # @return [Array<CoverageItem>] Filtered array of items
    def filtered_items
      @filtered_items ||= coverage_items.select do |item|
        (include_item_prefix?(item) || include_target_prefix?(item)) && !item.name.include?("$")
      end
    end

    # Combine item filename with prefix.
    #
    # @param item [CoverageItem] Coverage item to create the full filename.
    # @return [String] Combined filename.
    def include_item_prefix?(item)
      prefixed = "".dup
      if filename_prefix
        prefixed << filename_prefix
        prefixed << "/" unless filename_prefix.chars.last == "/"
      end
      prefixed << item.filename

      result = false
      target_files.each do |target_file|
        result = target_file.eql?(prefixed)
        break if result
      end
      result
    end

    def include_target_prefix?(item)
      result = false
      target_files.each do |target_file|
        prefixed = "".dup
        if filename_prefix
          prefixed << filename_prefix
          prefixed << "/" unless filename_prefix.chars.last == "/"
        end
        prefixed << target_file
        result = prefixed.eql?(item.filename)
        break if result
      end
      result
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
