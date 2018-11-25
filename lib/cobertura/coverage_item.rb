# frozen_string_literal: true

class CoverageItem
  def initialize(node)
    @node = node
  end

  def total_percentage
    @total_percentage ||= ((branch_rate + line_rate) / 2) * 100
  end

  def branch_rate
    @branch_rate ||= @node.attribute("branch-rate").value.to_f
  end

  def line_rate
    @line_rate ||= @node.attribute("line-rate").value.to_f
  end

  def file_name
    @file_name ||= @node.attribute("filename").value.to_s
  end

  def name
    @name ||= @node.attribute("name").value.to_s
  end
end
