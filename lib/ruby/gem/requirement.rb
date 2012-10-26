class Gem::Requirement
  # TODO: refactor Doubleshot to only use satisfied_by?(Gem::Version) instead of satisfies?(String|Gem::Version)
  def satisfies?(version)
    unless version.is_a? Gem::Version
      version = Gem::Version.new(version.to_s)
    end
    satisfied_by? version
  end
  alias :satisfies :satisfies?

  def eql?(other)
    self == other
  end
end