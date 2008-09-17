module Dev
  # TODO need to maintain separate fixtures for testing_ui? and !testing_ui?
  def update_fixture_file(timeline)
    File.open(timeline_fixture_path, "w+") { |f| f.puts timeline.to_yaml }
  end
  
  def timeline_fixture_path
    File.join Dir.pwd, "#{@which_timeline || :friends}.yml"
  end
  
  # When returning true, disables all API calls and uses fixtures
  # for testing UI changes and related behaviors.
  def testing_ui?
    # true
  end
end
