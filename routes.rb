require 'sinatra'
require './histogram'

get '/' do
  status 405
  send_file File.join(settings.public_folder, 'index.html')
end

get '/version' do
  content_type 'application/json'
  '{"version": "0.3.0"}'
end

post '/' do
  img=Magick::Image.from_blob(params[:file][:tempfile].read).first
  headers['Content-Disposition'] = 'attachment; filename="response.png"'
  content_type 'image/png'
  circle_histogram img
end

put '/' do
  img=Magick::Image.from_blob(request.body.read).first
  content_type 'image/png'
  circle_histogram img
end
