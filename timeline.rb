module Timeline
  # TODO this method smells funny, can probably be cleaned up
  def load_timeline
    @timeline = if @which_timeline
      load_timeline_from_api @which_timeline
    elsif @new_status
      timeline = load_timeline_from_api
      if timeline.map(&:id).include?(@new_status.id)
        @new_status = nil
      else
        timeline = [@new_status] + timeline
      end
      timeline
    elsif testing_ui?
      update_fixture_file load_timeline_from_api if not File.exist?(timeline_fixture_path)
      load_timeline_from_cache
    else
      load_timeline_from_api
    end || []
    
    @timeline = @timeline.first(10)
    
    @timeline = [fail_status] + load_timeline_from_cache if @timeline.empty?
    
    update_fixture_file @timeline
  end
  
  def load_timeline_from_api(which = :friends)
    twitter_api { @twitter.timeline which }
  end
  
  def load_timeline_from_cache
    YAML.load_file timeline_fixture_path
  end
  
  def reload_timeline
    load_timeline
    @timeline_stack.clear { populate_timeline }
    
    # TODO fix this
    # growl_latest
  end
  
  def update_status
    if testing_ui?
      status = Twitter::Status.new do |s|
        s.text = @status.text
        s.user = @timeline.first.user
        s.created_at = Time.new
        s.id = @timeline.first.id.to_i + 1
      end
      
      timeline = [status] + @timeline[0..-2]
      update_fixture_file timeline
      reload_timeline
      # visit "/timeline"
    else
      @new_status = twitter_api { @twitter.update @status.text }
      reload_timeline
      # visit "/timeline"
    end
    
    reset_status
  end
  
  # Layout for timeline
  def populate_timeline
    @menus = {}
    @timeline.each do |status|
      @current_user = status.user
      
      flow :margin => 0 do
        zebra_stripe gray(0.9)
        
        stack :width => -(45 + gutter) do
          # para autolink(@htmlentities.decode(status.text)), :size => 9, :margin => 5
          para autolink(status.text), :size => 9, :margin => 5
          menu_for status
        end
        
        unless @last_user and @last_user.id == @current_user.id
          stack :width => 45 do
            avatar_for status.user
            para link_to_profile(status.user), :size => 8, :align => "right", :margin => [0,0,5,5]
          end
        end
      end
      
      @last_user = @current_user
    end
  end
  
  def reset_status
    @status.text = ""
    @counter.text = ""
    @status.focus
  end
end