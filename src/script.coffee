
{render, div, raw, img} = teacup

large = medium = small = null

do refreshSize = ->
	bodyWid = $('body').width()
	large = (bodyWid/ 4) + 'px'
	medium = (bodyWid/ 6) + 'px'
	small = (bodyWid/12) + 'px'
	
	for hdrId in ['high']
		$('#' + hdrId).css fontSize: large
	
	for hdrId in ['rain', 'humidity', 'cloudcover', 'phrase']
		$('#' + hdrId).css fontSize: small

setInterval refreshSize, 1000

refreshFore = ->
	$.getJSON '/forecast', (data) ->
		{iconURL, high, phrase, rain, wind, humidity, cloudcover} = data
		
		$('#forecast').replaceWith render ->
			div '#forecast', style:'clear:both; float:left; width:100%; height:45%', ->
				div '#row1', style:'clear:both; float:left; margin-top:5%;
									width:100%; height:50%', ->
					div style:'clear:both; float:left; margin-left:2%; 
								position: relative; left: 5%;
								width:35%; height:100%', ->
						img style:'width:100%; height:100%', src: iconURL
					div style:'float:right; text-align:right; color:white;
								position:relative; top:1%;
								width:40%; margin-right:10%;', ->
						div '#high', -> raw Math.ceil high
			
				div '#row2', style:'clear:both; float:left; margin-top:3%;
									color:white; width:100%; height:20%', ->
					div style:'clear:both; float:left; margin-left:10%; 
							   width:45%', ->
						div '#phrase', ->
							raw (if phrase then phrase.replace(/\s/g, '&nbsp;') else '')
					div style:'float:right; margin-right:10%; 
								width:35%; text-align:right', ->
						div '#humidity', 
							(if humidity then humidity + '%' else '')
			
				div '#row3', style:'clear:both; float:left;  margin-top:3%; margin-bottom:3%;
									color:white; width:100%; height:20%', ->
					div style:'clear:both; float:left; margin-left:10%; 
							width:48%', ->
						div '#cloudcover', (if cloudcover then 'Clouds ' + cloudcover + '%'  else '')
					div style:'float:right; margin-right:10%;
							width:32%; text-align:right', ->
						div '#rain', (if rain? then 'Rain ' + rain + '"' else '')
					div style:'clear:both'
				div style:'height:3%', '&nbsp;'
				
flash   = 'no'		
dateMS  = ''

refreshCurAndTime = -> 
	$.get '/cumulus/realtime.txt', (data) ->
		rtData  = data.split ' '
		temp 	= rtData[2]
		hum  	= rtData[3]
		avgWind = Math.round rtData[5]
		gust	= Math.round rtData[40]
		$('#current').replaceWith render ->
			div '#current', style:'clear:both; float:left; position:relative; top:8%;
				width:100%; height:36%', ->
				div style:'clear:both; float:left; margin:10% 0 2% 10%; 
						color:white; font-size:' + medium, ->
					raw temp + '&deg; &nbsp; ' + hum+'%'
	
	$.getJSON '/cumulus/flash', (data) -> {flash, dateMS} = data
	
	date = new Date() 
	dow  = date.getDay()
	dowStr = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][dow]
	$('#dow').css(fontSize: medium).text dowStr
	
	date = new Date +dateMS
	hour = ['12', ' 1', ' 2', ' 3', ' 4', ' 5', 
			' 6', ' 7', ' 8', ' 9', '10', '11'][date.getHours() % 12]
	mins = '' + date.getMinutes()
	if mins.length < 2 then mins = '0' + mins
	$('#time').css(fontSize: medium).html hour + ':' + mins + '<br>&nbsp;<br>&nbsp;'
 
lastHour = null
setInterval ->
	date = new Date()
	hour = date.getHours()
	if lastHour isnt hour
		lastHour = hour
		refreshFore()
	refreshCurAndTime()
, 5000

dowColor = 'white'

setInterval ->
	$('#dow').css color: dowColor
	if flash is 'yes'
		if dowColor is 'white' then dowColor = 'blue' else dowColor = 'white'
	else
		dowColor = 'white'
, 750

$ ->
	$('body').on 'click', '#dow', -> 
		flash = 'no'
		$.get '/cumulus/flash', clear: 1
	
	refreshFore()
	refreshCurAndTime()
