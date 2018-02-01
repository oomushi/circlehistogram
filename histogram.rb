require 'rmagick'
require 'matrix'

def circle_histogram img
  histogram=[[0]*256,[0]*256,[0]*256]
  q=Magick::QuantumRange/255
  img.each_pixel do |pixel, c, r|
    histogram[0][pixel.red/q]+=1
    histogram[1][pixel.green/q]+=1
    histogram[2][pixel.blue/q]+=1
  end

  angle1=2.0*Math::PI/histogram[0].size
  angle2=angle1/2.0
  tg=Math.tan angle2
  max=histogram.reduce(0){|l,a| [a.max, l].max}
  l=[511,max].min
  prop=1.0*l/max

  channels=[]
  alpha=Magick::Image.new(l*2+1,l*2+1) do |i|
    i.format='PNG'
    i.background_color = '#000000'
  end
  
  histogram.each do |values|
    canvas = Magick::Image.new l*2+1,l*2+1 do |i|
      i.format='PNG'
      i.background_color = '#00000000'
    end
    values.each_with_index do |value,i|
      color = "##{"%02X"%i}#{"%02X"%i}#{"%02X"%i}ff"
      path = Magick::Draw.new
      path.fill color
      path.stroke color
      angle = angle1*i
      transform = Matrix[[Math.cos(angle), -Math.sin(angle)],[Math.sin(angle), Math.cos(angle)]]
      value*=prop
      points = Matrix[[0,value,value],[0,value*tg,-value*tg]]
      points = transform*points
      points += Matrix[[l,l,l],[l,l,l]]
      path.polygon(points[0,0],points[1,0],points[0,1],points[1,1],points[0,2],points[1,2])
      path.draw canvas
    end
    channels << canvas
    talpha = canvas.channel Magick::OpacityChannel
    alpha.composite!(talpha.negate,0,0,Magick::LightenCompositeOp)
  end
  channels << alpha
  img = Magick::Image.new l*2+1,l*2+1 do |i|
    i.format='PNG'
    i.background_color = '#00000000'
  end
  [Magick::CopyRedCompositeOp,
   Magick::CopyGreenCompositeOp,
   Magick::CopyBlueCompositeOp,
   Magick::CopyOpacityCompositeOp].each_with_index do |op,i|
    img.composite!(channels[i],0,0,op)
  end
  img.to_blob
end
