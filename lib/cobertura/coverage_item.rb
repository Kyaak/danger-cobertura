# frozen_string_literal: true

# Container item for cobertura <class> entries
class CoverageItem
  # @param node [Oga::XML::NodeSet] An xml node set containing the class information of a cobertura report.
  def initialize(node)
    @node = node
  end

  # @return [Float] The combined coverage of branch and line rate
  def total_percentage
    @total_percentage ||= (branch_rate + line_rate) / 2
  end

  # @return [Float] The branch coverage rate
  def branch_rate
    @branch_rate ||= @node.attribute("branch-rate").value.to_f * 100
  end

  # @return [Float] The line coverage rate
  def line_rate
    @line_rate ||= @node.attribute("line-rate").value.to_f * 100
  end

  # @return [String] Name of the class file with directory path
  def file_name
    @file_name ||= @node.attribute("filename").value.to_s
  end

  # @return [String] Name of the class file with package structure
  def name
    @name ||= @node.attribute("name").value.to_s
  end
end
