###
    serve custom web page to show forecast and current pws stats in bathroom display

    cd /bath
    coffee -cmo lib src/srvr.coffee
###

console.log process.cwd()
console.log __dirname 	

# process.chdir '~/apps/bath'

fs		   	= require 'fs'
url 		  = require 'url'
http    	= require 'http'
request 	= require 'request'
cheerio 	= require 'cheerio'
nodeStatic  = require 'node-static'
fileServer	= new nodeStatic.Server null #, cache: 0
sqlite3     = require("sqlite3").verbose()

# nodemailer = require "nodemailer"
# transporter = nodemailer.createTransport
#   service: "Gmail"
#   auth:
#     user: "mark@hahnca.com"
#     pass: "GHJlkjert987"
# mailOptions =
#   from: "mark@hahnca.com"
#   to: "mark@hahnca.com"
#   subject: "Pill warning"
#   text: "Pill warning"
#   html: "Pill warning"
# 
# lastEmail = 0 #Date.now()
# sendWarningEmail = ->
#   lastEmail = Date.now()
#   transporter.sendMail mailOptions, (error, info) ->
#     if error
#       console.log error
#     else
#       console.log "Message sent: " + info.response

getWxData = (cb) ->
  db = new sqlite3.Database '/var/lib/weewx/weewx.sdb', sqlite3.OPEN_READONLY, (err) ->
    if err then console.log 'Error opening weewx db', err; cb? err; return
    db.get 'SELECT outTemp, outHumidity FROM archive ORDER BY  dateTime DESC LIMIT 1', (err, res) ->
      if err
        console.log 'Error reading weewx db', err
        db.close()
        cb? err
        return
      # console.log 'getWxData', res
      cb? res
      db.close()

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

cacheTime = 0
days = null
forecastURL = 'http://api.wunderground.com/api/0ab64c6b7d983f0e/forecast/q/33.840404,-118.186365.json'

do getForecast = ->
  if Date.now() > cacheTime + 10 * 60 * 1000
    request forecastURL, (err, resp, data) ->
      data = JSON.parse data
      days = data.forecast.simpleforecast.forecastday
      cacheTime = Date.now()
      console.log 'Accessed weather underground and got ' + days.length + ' days.'

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
            div '#forecast', style:'width:100%; height:45%'
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
  
  if req.url[0..8] is '/forecast'
    dayOfs = +url.parse(req.url, true).query.dayOfs

    getForecast()
    
    if days  
      
      for day, dayIdx in days
        if Date.now() < (day.date.epoch - 3*60*60)*1000
          break
      
      day = days[(dayIdx + dayOfs) % days.length]
      
      # console.log require('util').inspect({dayIdx, dayOfs, days},depth:null), Date.now()
      
      iconURL    = day.icon_url
      high       = day.high.fahrenheit
      phrase     = day.conditions
      rain       = day.qpf_allday.in
      wind       = day.avewind.mph
      humidity   = day.avehumidity
      dayOfWeek  = day.date.weekday
      
    else
      
      iconURL = 'http://icons.wxug.com/i/c/k/clear.gif'
      high = 0
      phrase=''
      rain = 0
      wind = 0
      humidity=50
      dayOfWeek='Please wait...'
  
    # console.log require('util').inspect {iconURL, high, phrase, rain, wind, humidity, dayOfWeek}, depth:null
    
    res.writeHead 200, "Content-Type": "text/json"
    res.end JSON.stringify {iconURL, high, phrase, rain, wind, humidity, dayOfWeek}
    return

  # if req.url[0..5] is '/flash'
  #   if url.parse(req.url, true).query.clear is '1'
  #     fs.writeFileSync 'flash', 'no'
  #   try
  #     flash = fs.readFileSync 'flash', 'utf8'
  #   catch e
  #   dateMS = Date.now()
  #   res.end JSON.stringify {flash, dateMS}
  #   return
  
  if req.url[0...9] is '/weewx'
    getWxData (data) -> res.end JSON.stringify {data}
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