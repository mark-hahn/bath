###
    serve custom web page to show forecast and current pws stats in bathroom display

    cd /bath
    coffee -cmo lib src/srvr.coffee
###

# console.log process.cwd()	# C:\WINDOWS\system32    C:\apps\bath
# console.log __dirname 		# C:\apps\bath\lib       C:\apps\bath\lib

process.chdir '/apps/bath'

fs			= require 'fs'
url 		= require 'url'
http    	= require 'http'
request 	= require 'request'
cheerio 	= require 'cheerio'
nodeStatic  = require 'node-static'
fileServer	= new nodeStatic.Server null, cache: 0
fileSrvrCum	= new nodeStatic.Server '/',  cache: 0
#fileSrvrLib	= new nodeStatic.Server '/apps/bath/lib',  cache: 0

nodemailer = require "nodemailer"
transporter = nodemailer.createTransport
  service: "Gmail"
  auth:
    user: "mark@hahnca.com"
    pass: "GHJlkjert987"
mailOptions =
  from: "mark@hahnca.com"
  to: "mark@hahnca.com"
  subject: "Pill warning"
  text: "Pill warning"
  html: "Pill warning"

lastEmail = 0 #Date.now()
sendWarningEmail = ->
  lastEmail = Date.now()
  transporter.sendMail mailOptions, (error, info) ->
    if error
      console.log error
    else
      console.log "Message sent: " + info.response

{render, doctype, html, head, title, body, div, img, raw, text, script} = require 'teacup'

# fs.writeFileSync 'flash', 'yes'

# setInterval ->
#   if new Date().getHours() is 5
#     fs.writeFileSync 'flash', 'yes'
#   try
#     flash = fs.readFileSync 'flash', 'utf8'
#   catch e
#     flash = 'no'
#   if flash is 'yes' and new Date().getHours() > 10 and
#       (Date.now() - lastEmail) > 60*60*1000
#     sendWarningEmail()
# , 10*60*1000

http.createServer (req, res) ->
  console.log 'req:', req.url
  if req.url is '/'
    res.writeHead 200, "Content-Type": "text/html"
    res.end render ->
      doctype()
      html ->
        head ->
          title 'forecast - bath'
        body style:'background-color:black', ->
          div style:'width:100%; height:1375px', ->
            div '#forecast'
            div style:'clear:both; float:left; width:100%; height:3px;
                  position: relative; top: 9%;
                  background-color:white; margin-top:-2%;'
            div '#current'
            div style:'clear:both; float:left; width:100%; height:3px;
                  position: relative; top: 0%;
                  background-color:white; margin-top:-2%;'
            div ->
              div '#dow', style:'clear:both; float:left; margin:5% 0 0% 12%;
                        color:white'
              div '#time', style:'float:right; margin:5% 9% 0% 0;
                        color:white;'

          script src: 'http://code.jquery.com/jquery-1.11.0.min.js'
          script src: 'lib/teacup.js'
          script src: 'lib/script.js'
    return
  
  forecastURL = 'http://www.myweather2.com/developer/weather.ashx?uac=Sp.zBdhFxh&uref=0900ec9b-28ee-4d21-92d6-e28b2817bac5&output=json'
  
  if req.url is '/forecast'
    request forecastURL, (err, resp, data) ->
      data = JSON.parse data
      # console.log require('util').inspect data, depth:null
      
      for fcst in data.weather.forecast
        if Date.now() > new Date(fcst.date).getTime()
          break
          
      day = fcst.day[0]
      
      # console.log fcst.date, 
      #            (fcst.day_max_temp * 9 / 5 + 32), 
      #            (day.precip_mm / 25.4),
      #             day.humidity,
      #             day.weather_text
      
      # console.log require('util').inspect fcst, depth:null
                    
      matches = /sunny|rain|clear/i.exec day.weather_text
      # console.log day.weather_text, matches
      
      icon = if not matches
        console.log 'no sunny|rain|clear match for', day.weather_text
        'xxx.gif'
      else
        switch matches[0].toLowerCase()
          when 'sunny', 'clear' then 'clear'
          when 'rain'           then 'showers'
          else '???'
            # then 'clouds'
            # then 'many-clouds'
            # then 'showers-day'
            # then 'showers-scattered-day'
            # then 'showers-scattered'
            # then 'storm-night'
            
      iconURL = '/lib/icons/Status-weather-' + icon + '-icon.png'
      
      rain = wind = humidity = cloudcover = phrase = high = '???'  #  visibility_km  wind.speed
      
      rain       = day.precip_mm / 25.4
      wind       = day.wind.speed
      humidity   = day.humidity
      cloudcover = day.cloudcover
      phrase     = day.weather_text
      high       = fcst.day_max_temp * 9 / 5 + 32
        
      res.writeHead 200, "Content-Type": "text/json"
      res.end JSON.stringify {iconURL, high, phrase, rain, wind, humidity, cloudcover}
    return

  # http://www.myweather2.com/Images/weather/Rainy.gif
  
  if req.url[0..13] is '/cumulus/flash'
    if url.parse(req.url, true).query.clear is '1'
      fs.writeFileSync 'flash', 'no'
    try
      flash = fs.readFileSync 'flash', 'utf8'
    catch e
    dateMS = Date.now()
    res.end JSON.stringify {flash, dateMS}
    return

  if req.url[0...9] is '/cumulus/'
    req.addListener('end', ->
      fileSrvrCum.serve req, res, (err) ->
        if err then console.log 'cumulus file server error\n', req.url, err
    ).resume()
    return

  if req.url in ['/teacup.js', '/script.js']
    req.addListener('end', ->
      fileServer.serve req, res, (err) ->
        if err then console.log 'file server lib error\n', req.url, err
    ).resume()
    return

  if req.url[0...7] is '/icons/'
    req.addListener('end', ->
      fileServer.serve req, res, (err) ->
        if err then console.log 'file server lib error\n', req.url, err
    ).resume()
    return

  req.addListener('end', ->
    fileServer.serve req, res, (err) ->
      if err and req.url[-4..-1] not in ['.ico', '.map']
        console.log 'file server error\n', req.url, err
  ).resume()

.listen 1337


console.log 'listening on port 1337'


###
          tu  we  th
wund web  85  87  83
accuwthr  85  85  83
mywthr2   84  88  84
google    84  86  86
weather2  82  89  84
wthrchan  80  84  82
wund api  80  83  82
willywthr 80  82  79
intlicast 79  85  82
frcst.io  75  78  79
wthrbug   75  75  75
openwthr  70  70  70  
###