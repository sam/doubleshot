class Pathname
  def touch(path)
    file = self + path
    file.open("w+") { nil } unless file.exist?
    file
  end

  def child_of?(p2)
    expand_path.to_s.include?(p2.expand_path.to_s)
  end

  def to_url
    java.io.File.new(to_s).to_url.to_s
  end

  def hidden?
    path = expand_path

    until path.root?
      return true if path.basename.to_s.start_with? "."
      path = path.parent
    end

    false
  end
end