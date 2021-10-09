###
    serve custom web page to show forecast and current pws stats in bathroom display

    cd /bath
    coffee -cmo lib src/srvr.coffee

api doc ...
    https://docs.google.com/document/d/1_Zte7-SdOjnzBttb1-Y9e0Wgl0_3tah9dSwXUyEA3-c/edit
    
###

fs		   	= require 'fs'
url 		  = require 'url'
http    	= require 'http'
request 	= require 'request'
cheerio 	= require 'cheerio'
nodeStatic  = require 'node-static'
fileServer	= new nodeStatic.Server null #, cache: 0
sqlite3     = require("sqlite3").verbose()

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
      logd error
    else
      logd "Message sent: " + info.response

logd = (args...) -> 
  # console.log((new Date()).toLocaleString()
  console.log('srvr:', (new Date()).toLocaleString(), args...)

getWxData = (cb) ->
  db = new sqlite3.Database '/var/lib/weewx/weewx.sdb', sqlite3.OPEN_READONLY, (err) ->
    if err then logd 'Error opening weewx db', err; cb? err; return
    db.get 'SELECT outTemp, outHumidity FROM archive ORDER BY  dateTime DESC LIMIT 1', (err, res) ->
      if err
        logd 'Error reading weewx db', err
        db.close()
        cb? err
        return
      # logd 'getWxData', res
      cb? res
      db.close()

{render, doctype, html, head, title, body, div, img, raw, text, script} = require 'teacup'

fs.writeFileSync 'flash', 'yes'

setInterval ->
  if new Date().getHours() is 5
    fs.writeFileSync 'flash', 'yes'
  try
    flash = fs.readFileSync 'flash', 'utf8'
  catch e
    flash = 'no'
  if flash is 'yes' and new Date().getHours() > 10 and
      (Date.now() - lastEmail) > 60*60*1000
    sendWarningEmail()
, 10*60*1000

###
{ dayOfWeek:
   [ 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday' ],
  expirationTimeUtc:
   [ 1567217117,
     1567217117,
     1567217117,
     1567217117,
     1567217117,
     1567217117 ],
  narrative:
   [ 'Clear. Lows overnight in the upper 60s.',
     'Sunny. Highs in the upper 80s and lows in the upper 60s.',
     'Abundant sunshine. Highs in the low 90s and lows in the low 70s.',
     'Sunshine. Highs in the upper 80s and lows in the low 70s.',
     'Abundant sunshine. Highs in the upper 80s and lows in the low 70s.',
     'Abundant sunshine. Highs in the low 90s and lows in the low 70s.' ],
  temperatureMax: [ null, 89, 92, 89, 89, 90 ],
  temperatureMin: [ 69, 69, 70, 71, 71, 71 ],
  validTimeUtc:
   [ 1567173600,
     1567260000,
     1567346400,
     1567432800,
     1567519200,
     1567605600 ],
  daypart:
   [ { cloudCover: [Array],
       dayOrNight: [Array],
       daypartName: [Array],
       iconCode: [Array],
       iconCodeExtend: [Array],
       narrative: [Array],
       precipChance: [Array],
       precipType: [Array],
       qpf: [Array],
       qpfSnow: [Array],
       qualifierCode: [Array],
       qualifierPhrase: [Array],
       relativeHumidity: [Array],
       snowRange: [Array],
       temperature: [Array],
       temperatureHeatIndex: [Array],
       temperatureWindChill: [Array],
       thunderCategory: [Array],
       thunderIndex: [Array],
       uvDescription: [Array],
       uvIndex: [Array],
       windDirection: [Array],
       windDirectionCardinal: [Array],
       windPhrase: [Array],
       windSpeed: [Array],
       wxPhraseLong: [Array],
       wxPhraseShort: [Array] 

###
cacheTime = 0
days = null
daypart = null
data = {}
forecastURL = 'https://api.weather.com/v3/wx/forecast/daily/5day?geocode=33.840404,-118.186365&format=json' +
              '&units=e&language=en-US&apiKey=e727e7d0cd694a5da7e7d0cd69fa5dec'

do getForecast = ->
  if Date.now() > cacheTime + 10 * 60 * 1000
    request forecastURL, (err, resp, datain) ->
      try
        data = JSON.parse datain  
        days = data.dayOfWeek
        logd 'Accessed api.weather.com and got ' + days.length + ' days.'
        cacheTime = Date.now()
        daypart = data.daypart[0]
      catch errCaught 
        logd 'error accessing api.weather.com\n', {errCaught, forecastURL, err, resp, data}

http.createServer (req, res) ->
  if not req.url.startsWith '/weewx'
    logd 'req:', req.url
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
        if Date.now() < data.validTimeUtc[dayIdx]*1000 + 10*60*60*1000
          break

      day1 = dayIdx;
      dayIdx    = (day1 + dayOfs) % days.length
      daypIdx   = dayIdx * 2
      if not daypart.iconCode[daypIdx]
        dayIdx = (dayIdx+1) % days.length
        daypIdx   = dayIdx * 2
      daypName  = daypart.daypartName[daypIdx]

      logd {dayIdx,daypIdx,daypName}

      # phrase = daypart[0].daypartName
      # wxPhraseLong[dayIdx]
      # logd {phrase}

      # logd require('util').inspect({dayIdx, dayOfs, days},depth:null), Date.now()
      if day
        iconCode   = daypart.iconCode[daypIdx]
        # if iconCode.length < 2
        #   iconCode = '0' + iconCode
        iconURL = 'icons/' + iconCode + '.png'
        high       = daypart.temperature[daypIdx]
        phrase     = daypart.wxPhraseLong[daypIdx]
        rain       = daypart.precipChance[daypIdx]
        wind       = daypart.windSpeed[daypIdx]
        humidity   = daypart.relativeHumidity[daypIdx]
        dayOfWeek  = daypName

    else
      iconURL = 'icons/00.png'
      high = 0
      phrase=''
      rain = 0
      wind = 0
      humidity=50
      dayOfWeek='Please wait...'

    # logd require('util').inspect {iconURL, high, phrase, rain, wind, humidity, dayOfWeek}, depth:null

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
        if err then logd 'file server lib error\n', req.url, err
    ).resume()
    return

  if req.url[0...7] is '/icons/'
    req.addListener('end', ->
      fileServer.serve req, res, (err) ->
        if err then logd 'file server lib error\n', req.url, err
    ).resume()
    return

  req.addListener('end', ->
    fileServer.serve req, res, (err) ->
      if err and req.url[-4..-1] not in ['.ico', '.map']
        logd 'file server error\n', req.url, err
  ).resume()

.listen 1337


logd 'listening on port 1337'
