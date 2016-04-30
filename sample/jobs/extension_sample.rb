module ExtensionSample
  def ext_method
    puts "before"
    super
    puts "after"
  end
end
