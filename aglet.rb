Shoes.setup do
  gem "twitter"
  gem "htmlentities"
end

%w(
timeout
htmlentities
twitter

dev
errors
colors
helpers
grr
timeline
).each { |x| require x }

class Aglet < Shoes
  url "/",         :startup
  url "/setup",    :setup
  url "/timeline", :timeline
  
  include Dev, Errors, Colors, Helpers, Grr, Timeline
  
  ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
  
  def startup
    setup_cred
    @cred.empty? ? setup : timeline
  end
  
  def setup_cred
    return if @cred
    @cred_path = File.expand_path "~/.aglet_cred"
    @cred = File.exist?(@cred_path) ? File.readlines(@cred_path).map(&:strip) : []
  end
  
  def setup
    setup_cred
    
    background fail_to_white
    
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
    
    # @htmlentities = HTMLEntities.new
    
    @twitter = Twitter::Base.new *@cred
    # @friends = twitter_api { @twitter.friends.map(&:name) }
    
    background white
    
    @form = flow :margin => [0,0,0,5] do
      background fail_to_white
      
      @status = edit_box :width => -(10 + gutter), :height => 35, :margin => [5,5,5,0] do |s|
        if s.text.chomp!
          update_status
        else
          @counter.text = (size = s.text.size).zero? ? "" : size
          @counter.style :stroke => (s.text.size > 140 ? red : @counter_default_stroke)
        end
      end
      
      @counter_default_stroke = black
      @counter = strong ""
      para @counter, :size => 8, :margin => [0,8,0,0], :stroke => @counter_default_stroke
    end
    
    @timeline_stack = stack :height => 500, :scroll => true
    
    @footer = flow :height => 28 do
      background black
      with_options :stroke => white, :size => 8, :margin => [0,4,5,0] do |m|
        # TODO
        # @collapsed = check do |c|
        # end
        # m.para "collapsed"
        
        # XXX
        # This used to work. Something changed in Shoes and now any 
        # time after the first load of timeline,
        # the rendering gets fucked up when :reload_timeline fires.
        # using :visit fixes this but fucks up other plans
        # because it resets instance variables, which is a 
        # problem for how the @public check works.
        @public = check do |c|
          @which_timeline = (:public if c.checked?)
          reload_timeline
        end
        m.para "public"
        
        m.para " | ", link("setup", :click => "/setup")
      end
    end
    
    ###
    
    reload_timeline
    reset_status
    
    every 60 do
      reload_timeline
    end unless testing_ui?
  end
end

Shoes.app :title => "Aglet", :width => 275, :height => 565, :resizable => false
