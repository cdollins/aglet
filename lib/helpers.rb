module Helpers
  def link_to_status(status)
    link time_ago(status.created_at),
      :click => "http://twitter.com/#{status.user.screen_name}/statuses/#{status.id}"
  end
  
  def link_to_reply(user)
    link "reply" do
      @status.text += "@#{user.screen_name} "
      @status.focus
    end
  end
  
  def link_to_direct(user)
    link "direct" do
      @status.text += "d #{user.screen_name} "
      @status.focus
    end
  end
  
  def link_to_profile(user)
    link user.screen_name, :click => "http://twitter.com/#{user.screen_name}"
  end
  
  def link_to_unfollow(user)
    link "unfollow" do
      @twitter.destroy_friendship user.screen_name
      reload_timeline
    end
  end
  
  def link_to_destroy(status)
    link "destroy" do
      @twitter.destroy status.id
      reload_timeline
    end
  end
  
  ###
  
  def menu_for(status)
    flow :margin => [5,0,0,0] do
      with_options :size => 7, :margin => [0,0,5,5] do |m|
        m.para link_to_status(status)  unless failwhale? status.user
        m.para *menu_items_for(status)
      end
    end
  end
  
  def menu_items_for(status)
    items = []
    
    if not you?(status.user) and not failwhale?(status.user)
      items.concat [link_to_reply(status.user), " ", link_to_direct(status.user)]
    end
    
    if you? status.user
      items.concat [" ", link_to_destroy(status)]
    end
    
    items.shift if items.first == " "
    
    items
  end
  
  def unfollow_relevant?(user)
    (@which_timeline != :public) and not you?(user) and not failwhale?(user)
  end
  
  def you?(user)
    @cred[0] == user.screen_name
  end
  
  def failwhale?(user)
    user.screen_name == "failwhale"
  end
  
  ###
  
  def avatar_for(user)
    image testing_ui? ? "images/superman_selleck.jpg" : user.profile_image_url,
      :width => 45, :height => 45, :radius => 5, :margin => [5,5,5,3]
  # Something crashing Shoes in there..
  rescue Object => e
    error e.message
    fail_whale
  end
  
  def image(path, opts = {})
    # scaling - http://article.gmane.org/gmane.comp.lib.shoes/1384/match=scaling+images
    w, h = imagesize path
    return super unless w and h
    ow, oh = opts[:width], opts[:height]
    if ow && !oh
      opts[:height] = (ow.is_a? Float) ? ow : (ow * h/w.to_f).to_i
    elsif oh && !ow
      opts[:width]  = (oh.is_a? Float) ? oh : (oh * w/h.to_f).to_i
    end
    super path, opts
  end
  
  ###
  
  def zebra_stripe(color)
    @zebra_stripe = if @zebra_stripe
      background color
      false
    else
      true
    end
  end
  
  # TODO something like HTML labels where we can associate them with an input
  def label(text, options = {}, &block)
    para text.upcase, { :size => 8 }.merge(options)
  end
  
  ###
  
  # TODO this breaks if you refer to @user posessively e.g. @user's stuff.
  # Problem is related to the very simple Regexp used to break the 
  # status text into tokens in the first place, see :autolink
  #
  # It also breaks if you ahve something like an ellipsis after the username.
  # Need more smarter!!
  def at_pattern
    "[^\s!?.]+"
  end
  
  def autolink(text)
    escaped(text).strip.scan(/(\S+)(\s+)?/).flatten.map do |token|
      case token
      when /^@#{at_pattern}$/
        link token, :click => "http://twitter.com/#{username_from token}"
      when /^(http:\/\/|www\.)\S+$/
        link token, :click => "#{"http://" if $1 =~ /www/}#{token}"
      else token
      end
    end
  end
  
  # XXX temp hack for bug about too much escaping :\
  def escaped(text)
    CGI.unescapeHTML(CGI.unescapeHTML(text))
  end
  
  # A @username token might be grabbed with an attached piece of punctuation or similar
  # when parsing the status text for linkable tokens.
  def username_from(at_token)
    # TODO sub! here is hack for referring to @ users posessively
    # e.g. going to the bar for @foobar's birthday
    # Adding ' to the at_pattern generically means it wont match right
    # for autolink recognition right now.
    at_token[1..-1][Regexp.new(at_pattern.sub!("]", "']"))]
  end
  
  ###
  
  # Based on distance_of_time_in_words from Rails' ActionView.
  def time_ago(from, to = Time.new, include_seconds = false)
    from = Time.parse from
    
    distance = (to - from).abs
    minutes  = (distance / 60).round
    seconds  = distance.round
    
    case minutes
      when 0..1
        return (minutes == 0) ? "< 1 min" : "1 min" unless include_seconds
        case seconds
          when 0..4   then '< 5s'
          when 5..9   then '< 10s'
          when 10..19 then '< 20s'
          when 20..39 then '30s'
          when 40..59 then '< 1 min'
          else             '1 min'
        end

      when 2..44           then "#{minutes} min"
      when 45..89          then '1 hr'
      when 90..1439        then "#{(minutes.to_f / 60.0).round} hrs"
      when 1440..2879      then '1 day'
      when 2880..43199     then "#{(minutes / 1440).round} days"
      when 43200..86399    then '1 month'
      when 86400..525599   then "#{(minutes / 43200).round} months"
      when 525600..1051199 then '1 yr'
      else                      "over #{(minutes / 525600).round} yrs"
    end
  end
  
  # def time_ago_bg(from, to = Time.new, include_seconds = false)
  #   from = Time.parse from
  #   
  #   distance = (to - from).abs
  #   minutes  = (distance / 60).round
  #   seconds  = distance.round
  #   
  #   sec = [0.99, 0.95, 0.9, 0.85].map { |x| gray x }
  #   min = gray(0.7)
  #   hrs = gray(0.5)
  #   day = gray(0.3)
  #   yrs = gray(0.1)
  #   
  #   bg = case minutes
  #     when 0..1
  #       return background(min) unless include_seconds
  #       case seconds
  #         when 0..4   then sec[0]
  #         when 5..9   then sec[1]
  #         when 10..19 then sec[2]
  #         when 20..39 then sec[3]
  #         when 40..59 then min
  #         else             min
  #       end
  #     
  #     when 2..44           then min
  #     when 45..89          then hrs
  #     when 90..1439        then hrs
  #     when 1440..2879      then day
  #     when 2880..43199     then day
  #     when 43200..86399    then yrs # months
  #     when 86400..525599   then yrs # months
  #     when 525600..1051199 then yrs
  #     else                      yrs
  #   end
  #   
  #   background bg
  # end
end
