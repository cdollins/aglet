Shoes.setup do
  gem "twitter"
end

%w(
timeout
twitter

colors
dev
errors
helpers

grr
).each { |x| require x }

class Aglet < Shoes
  url "/",         :startup
  url "/setup",    :setup
  url "/timeline", :timeline
  
  include Colors, Dev, Errors, Helpers, Grr
  
  ### TODO move all this timeline handling stuff out somewhere else
  
  def load_timeline(thing = nil)
    @timeline = if thing == :public
      load_timeline_from_api :public
    elsif thing.is_a? Twitter::Status
      timeline = load_timeline_from_api
      timeline = [thing] + timeline if not thing == timeline.first
      timeline
    elsif testing_ui?
      update_fixture_file load_timeline_from_api if not File.exist?(timeline_fixture_path)
      load_timeline_from_cache
    else
      load_timeline_from_api
    end || []
    
    @timeline = @timeline.first(10)
    
    update_fixture_file @timeline
  end
  
  def load_timeline_from_api(which = :friends)
    twitter_api { @twitter.timeline which }
  end
  
  def load_timeline_from_cache
    YAML.load_file timeline_fixture_path
  end
  
  def reload_timeline(thing = nil)
    info "reloading timeline"
    load_timeline thing
    
    if @timeline.any?
      @timeline_stack.clear { populate_timeline }
    else
      warn "timeline reloaded empty, Twitter is probably over capacity"
      @timeline = [fail_status] + load_timeline_from_cache
      @timeline_stack.clear { populate_timeline }
    end
    
    growl_latest
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
    else
      status = twitter_api { @twitter.update @status.text }
      reload_timeline status
    end
    
    reset_status
  end
  
  # Layout for timeline
  def populate_timeline
    @menus = {}
    @timeline.each do |status|
      flow :margin => 0 do
        zebra_stripe gray(0.9)
        
        stack :width => -(45 + gutter) do
          para autolink(status.text), :size => 9, :margin => 5
          menu_for status
        end
        
        stack :width => 45 do
          avatar_for status.user
          para link_to_profile(status.user), :size => 7, :align => "right",
            :margin => [0,0,5,5]
        end
      end
    end
  end
  
  def reset_status
    @status.text = ""
    @counter.text = ""
    @status.focus
  end
  
  ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
  
  def startup
    setup_cred
    @cred.empty? ? setup : timeline
  end
  
  def setup_cred
    @cred_path = File.expand_path("~/.aglet_cred")
    @cred = File.exist?(@cred_path) ? File.readlines(@cred_path).map(&:strip) : []
  end
  
  def setup
    setup_cred
    
    background fail_whale_blue
    
    para "SETUP"
    
    stack :margin_bottom => 5 do
      label "username"
      @username = edit_line @cred.first
    
      label "password"
      @password = password_line @cred.last
    end
    
    flow do
      button "save", :margin_right => 5 do
        File.open(@cred_path, "w+") { |f| f.puts @username.text, @password.password_text }
        info  "Saved #{@username.text.inspect} and #{@password.password_text.inspect}"
        alert "Thank you, this info is now stored at #{@cred_path}"
        visit "/timeline"
      end
      
      button "cancel" do
        visit "/timeline"
      end
    end
  end
  
  ###
  
  def timeline
    setup_cred
    
    @twitter = Twitter::Base.new *@cred
    # @friends = twitter_api { @twitter.friends.map(&:name) }
    
    background white

    # Longer entries will be published in full but truncated for mobile devices.
    recommended_status_length = 140

    @form = flow :margin => [0,0,0,5] do
      background fail_whale_blue
      
      @status = edit_box :width => -(55 + gutter), :height => 35, :margin => [5,5,5,0] do |s|
        if s.text.chomp!
          update_status
        else
          @counter.text = (size = s.text.size).zero? ? "" : size
          @counter.style :stroke => (s.text.size > recommended_status_length ? red : @counter_default_stroke)
        end
      end
      
      # @submit = button "»", :margin => 0 do
      #   update_status
      # end
      
      @counter_default_stroke = white
      @counter = strong ""
      para @counter, :size => 8, :margin => [0,8,0,0], :stroke => @counter_default_stroke
    end
    
    @timeline_stack = stack :height => 500, :scroll => true
    
    @footer = flow :height => 28 do
      background black
      with_options :stroke => white, :size => 8, :margin => [0,4,5,0] do |m|
        @collapsed = check do |c|
          # TODO
        end
        m.para "collapsed"
        
        @public = check do |c|
          reload_timeline((:public if c.checked?))
        end
        m.para "public"
        
        m.para " | ",
          link("setup", :click => "/setup")
      end
    end

    ###

    reload_timeline
    reset_status

    every 60 do
      # TODO does not reload :public
      reload_timeline
    end
  end
end

Shoes.app :title => "Aglet", :width => 275, :height => 565, :resizable => false
