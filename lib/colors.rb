module Colors
  def fail_whale_orange
    rgb 241, 90, 34
  end
  
  def fail_whale_blue
    rgb 108, 197, 195
  end
  
  def fail_to_white
    gradient fail_whale_blue, white
  end
end
