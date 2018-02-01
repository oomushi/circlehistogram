require 'sinatra'
require './histogram'

get '/' do
  status 405
  '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Circle Histogram</title></head><body><code>curl -X PUT -d @myfilename https://circlehisto.herokuapp.com</code> or <form method="POST" action="" enctype="multipart/form-data"><input type="file" name="file" /><input type="submit" /></form></body></html>'
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
