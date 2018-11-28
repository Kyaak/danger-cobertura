module Helpers
  def table_column_line(columns)
    result = "".dup
    (1..columns).each do |i|
      result << "-----"
      if i < columns
        result << "|"
      end
    end
    result
  end
end
