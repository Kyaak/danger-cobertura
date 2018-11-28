# Container item for cobertura <class> entries
class CoverageItem
  # Initialize an object using an xml node set containing the class information of a cobertura report.
  #
  # @param node [Oga::XML::NodeSet] NodeSet of a class
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
  def filename
    @filename ||= @node.attribute("filename").value.to_s
  end

  # @return [String] Name of the class file with package structure
  def name
    @name ||= @node.attribute("name").value.to_s
  end
end
