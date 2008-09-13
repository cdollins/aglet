## ERRRRRORRRRRR HANDLLLLLINNNGG!! (say in the voice of Jon Lovitz as The Thespian)
module Errors
  def twitter_api(&block)
    begin
      timeout &block
    rescue *twitter_errors
    end
  end
  
  def timeout(seconds = 1, &block)
    Timeout.timeout(seconds, &block)
  end
  
  def twitter_errors
    [Timeout::Error, Twitter::CantConnect]
  end
  
  def twitter_down!
    background fail_whale_orange
    image fail_whale_src, :width => 1.0, :height => 200
    para "Too many tweets!", :align => "center"
    para "Sorry, Twitter is over capacity. Wait, though, and ",
      "the timeline will reload as soon as it can.", :align => "center"
  end
  
  def fail_status
    Twitter::Status.new do |s|
      s.text = "Twitter is over capacity. Timeline will continue to attempt to reload."
      s.user = fail_user
      s.created_at = Time.new.to_s
    end
  end
  
  def fail_user
    Twitter::User.new do |u|
      u.profile_image_url = fail_whale_src
      u.name = "failwhale"
      u.screen_name = "failwhale"
      u.location = "an octopuses garden, in the shade"
      u.url = "http://blog.twitter.com"
      u.profile_background_color = fail_whale_orange
    end
  end
  
  def fail_whale
    image fail_whale_src, :width => 45, :height => 45, :margin => 5
  end
  
  def fail_whale_src
    "images/whale.png"
  end
end
