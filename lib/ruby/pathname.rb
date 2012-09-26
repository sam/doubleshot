class Pathname
  def touch(path)
    file = self + path
    file.open("w+") { nil }
    file
  end
end