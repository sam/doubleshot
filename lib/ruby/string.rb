class String

  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

  def camelize
    self.gsub(/\/(.?)/) { "::" + $1.upcase }.
    gsub(/(^|_|-)(.)/) { $2.upcase }
  end

  def ensure_ends_with(fragment)
    end_with?(fragment) ? self.dup : self + fragment
  end

  def ensure_starts_with(fragment)
    start_with?(fragment) ? self.dup : fragment + self
  end

  ##
  # Remove whitespace margin.
  #
  # @return [String] receiver with whitespace margin removed
  #
  # @api public
  def margin
    lines = self.dup.split($/)

    min_margin = 0
    lines.each do |line|
      if line =~ /^(\s+)/ && (min_margin == 0 || $1.size < min_margin)
        min_margin = $1.size
      end
    end
    lines.map { |line| line.sub(/^\s{#{min_margin}}/, '') }.join($/)
  end

end