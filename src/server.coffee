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

# forecastURL = 'http://www.wunderground.com/history/airport/KLGB/2014/11/12/MonthlyHistory.html?'
forecastURL = 'http://api.openweathermap.org/data/2.5/forecast?lat=33.840404&lon=-118.186365&units=imperial'

# require('./scrape') forecastURL, -> process.exit 0
# return

http.createServer (req, res) ->
  # console.log 'req:', req.url
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
                  position: relative; top: 0%;
                  background-color:white; margin-top:-2%;'
            div '#current'
            div style:'clear:both; float:left; width:100%; height:3px;
                  position: relative; top: 0%;
                  background-color:white; margin-top:-2%;'
            div ->
              div '#dow', style:'clear:both; float:left; margin:5% 0 0% 12%;
                        color:white'
              div '#time', style:'float:left; margin:5% 0 0% 12%;
                        color:white;'

          script src: 'http://code.jquery.com/jquery-1.11.0.min.js'
          script src: 'lib/teacup.js'
          script src: 'lib/script.js'
    return

  blnk = (str, pfx = '', sfx = '', replSpc = ' ') -> 
    if str 
      str = (str
          .replace(/\n|\s+/g, ' ')
          .replace(/^\s*/g, '')
          .replace(/\s*$/g, '')
          .replace(/\s/g, replSpc)
      )
      if str then pfx + str + sfx else ''
    else ''
  
  if req.url is '/forecast'
    $.json forecastURL, ->
    
    request forecastURL, (err, resp, twcHtml) ->
      # $ = cheerio.load twcHtml
      
      indent = ''
      dump = (ele) ->
        indent += '  '
        
        if ele.tagName is 'tr' then console.log()
        text = $(ele).clone().children().remove().end().text()
        console.log indent, 
                ele.tagName, 
                blnk( $(ele).attr('id'),    '#'         ), 
                blnk( $(ele).attr('class'), '.', '', '.'), 
                blnk( text,                 '"', '"'    ), 
                blnk( $(ele).attr('src'), 'src: '       ) 
        $(ele).children().each ->
          dump @
          
        indent = indent[0..-3]
  
      $section = $ 'td.day'
      console.log '$section.length', $section.length
      # $section.each (i) ->
      #   # hasF =  $(@).text().indexOf('Forecast:') > -1
      #   console.log i, $(@).text()
      dump $section[23]
      
      
      process.exit 0
      
      # console.log '$section.length', $section.length
      # 
      # $3cards = $section.children()
      # console.log '$3cards.length',     $3cards.length
      # console.log '$3cards[0].tagName', $3cards[0].tagName
      # console.log '$3cards[1].tagName', $3cards[1].tagName
      # console.log '$3cards.text()',     $3cards.text()
      # 
      # $3cards = $3cards.eq(0).
      # console.log '$3cards.length',     $3cards.length
      # console.log '$3cards[0].tagName', $3cards[0].tagName
      # console.log '$3cards[1].tagName', $3cards[1].tagName
      # console.log '$3cards.text()',     $3cards.text()
      # 
      # 
      # # todo  select proper one based on time-of-day
      # $card = $3cards.eq 1
      # 
      
      process.exit 0
      
      $cont = $ '#wx-forecast-container'

      $parts = $cont.find '.wx-data-part'

      if $parts.length
        iconURL    = $parts.eq(1).find('img').attr 'src'
        high       = $parts.eq(4).find('.wx-temperature').text()
        hiParts    = /^\d+/.exec high
        high	   = (if hiParts then hiParts[0] + '&deg;' else '')
        phrase     = $parts.eq(7).find('.wx-phrase').text()
        chanceRain = $parts.eq(10).text().split('\n')[2]

        $parts = $cont.find('.wx-collapsible').find '.wx-data-part'
        wind     = $parts.eq(1).find('.wx-wind-label').text()
        humidity = $parts.eq(4).find('.wx-data').text()
        uv       = $parts.eq(7).find('.wx-data').text().replace ' ', ''
      else
        $parts = $cont.find '.wx-daypart '
        if $parts.length
          $parts = $parts.eq(0)
          iconURL    = $parts.find('img').attr 'src'
          high       = $parts.find('.wx-temp').text()
          # console.log high
          hiParts    = /^\s*(\d+)/.exec high
          high	   = (if hiParts then hiParts[1] + '&deg;' else '')
          phrase     = $parts.find('.wx-phrase').text()
#					chanceRain = $parts.text().split('\n')[2]
#
#					$parts = $cont.find('.wx-collapsible').find '.wx-data-part'
#					wind     = $parts.eq(1).find('.wx-wind-label').text()
#					humidity = $parts.eq(4).find('.wx-data').text()
#					uv       = $parts.eq(7).find('.wx-data').text().replace ' ', ''
        else
          chanceRain = '??'
          wind = '??'
          humidity = '???'
          uv = '???'
          phrase = '???'

      res.writeHead 200, "Content-Type": "text/json"
      res.end JSON.stringify {iconURL, high, phrase, chanceRain, wind, humidity, uv}
    return

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

  req.addListener('end', ->
    fileServer.serve req, res, (err) ->
      if err and req.url[-4..-1] not in ['.ico', '.map']
        console.log 'file server error\n', req.url, err
  ).resume()

.listen 1337


console.log 'listening on port 1337'
