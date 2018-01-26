require 'sinatra'
require 'rmagick'
require 'matrix'

post '/' do
  content_type 'image/png'
  histogram=[[0]*256,[0]*256,[0]*256]
  Q=Magick::QuantumRange/255
  img=Magick::Image.from_blob(request.body.read).first
  img.each_pixel do |pixel, c, r|
    histogram[0][pixel.red/Q]+=1
    histogram[1][pixel.green/Q]+=1
    histogram[2][pixel.blue/Q]+=1
  end

  ANGLE=2.0*Math::PI/histogram[0].size
  ANGLE2=ANGLE/2.0
  TG=Math.tan ANGLE2
  MAX=histogram.reduce(0){|l,a| [a.max, l].max}
  L=[511,MAX].min
  PROP=1.0*L/MAX

  channels=[]
  alpha=Magick::Image.new(L*2+1,L*2+1) do |i|
    i.format='PNG'
    i.background_color = '#000000'
  end
  
  histogram.each do |values|
    canvas = Magick::Image.new L*2+1,L*2+1 do |i|
      i.format='PNG'
      i.background_color = '#00000000'
    end
    values.each_with_index do |value,i|
      color = "##{"%02X"%i}#{"%02X"%i}#{"%02X"%i}ff"
      path = Magick::Draw.new
      path.fill color
      path.stroke color
      angle = ANGLE*i
      transform = Matrix[[Math.cos(angle), -Math.sin(angle)],[Math.sin(angle), Math.cos(angle)]]
      value*=PROP
      points = Matrix[[0,value,value],[0,value*TG,-value*TG]]
      points = transform*points
      points += Matrix[[L,L,L],[L,L,L]]
      path.polygon(points[0,0],points[1,0],points[0,1],points[1,1],points[0,2],points[1,2])
      path.draw canvas
    end
    channels << canvas
    talpha = canvas.channel Magick::OpacityChannel
    alpha.composite!(talpha.negate,0,0,Magick::LightenCompositeOp)
  end
  channels << alpha
  img = Magick::Image.new L*2+1,L*2+1 do |i|
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
