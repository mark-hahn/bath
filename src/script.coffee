
render = teacup.render
div = teacup.div
raw = teacup.raw
img = teacup.img

large = medium = small = null

do refreshSize = ->
	bodyWid = $('body').width()
	large = (bodyWid/ 4) + 'px'
	medium = (bodyWid/ 6) + 'px'
	small = (bodyWid/12) + 'px'

	for hdrId in ['rain', 'humidity', 'dayOfWeek', 'phrase']
		$('#' + hdrId).css fontSize: small

setInterval refreshSize, 1000

dayOfs = 0

refreshFore = ->
	$.getJSON 'forecast', {dayOfs}, (data) ->
		iconURL = data.iconURL
		high = data.high
		phrase = data.phrase
		rain = data.rain
		wind = data.wind
		humidity = data.humidity
		dayOfWeek = data.dayOfWeek
		$('#forecast').replaceWith render ->
			div '#forecast', style:'clear:both; float:left; width:100%; height:45%', ->
				div '#row1', style:'clear:both; float:left; margin-top:5%;
									width:100%; height:50%', ->
					div style:'clear:both; float:left; margin-left:2%;
								position: relative; left: 5%;
								width:35%; height:100%', ->
						img style:'width:100%; height:100%', src: iconURL
					div style:'float:right; text-align:right; color:white;
								position:relative; top:40px;
								width:40%; margin-right:10%; font-size:175px;', ->
						div '#high', -> raw Math.ceil high

				div '#row2', style:'clear:both; float:left; margin-top:3%;
									color:white; width:100%; height:20%', ->
					div style:'clear:both; float:left; margin-left:10%;
							   width:45%', ->
						div '#dayOfWeek', (if dayOfWeek then dayOfWeek else '')
					div style:'float:right; margin-right:10%;
								width:35%; text-align:right', ->
						div '#humidity',
							(if humidity then humidity + '%' else '')

				div '#row3', style:'clear:both; float:left;  margin-top:3%; margin-bottom:3%;
									color:white; width:100%; height:20%', ->
					div style:'clear:both; float:left; margin-left:10%;
							width:48%', ->
						div '#phrase', ->
							raw (if phrase then phrase.replace(/\s/g, '&nbsp;') else '')
					div style:'float:right; margin-right:10%;
							width:32%; text-align:right', ->
						div '#rain', (if rain? then rain + '%' else '')
					div style:'clear:both'
				div style:'height:3%'

flash   = 'no'
dateMS  = ''

# get roof weather, update time, and check pill reminder
# called every five secs
refreshCurAndTime = ->
	$.get 'weewx', (data) ->
		data = JSON.parse data
		outTemp = Math.round data.data.outTemp
		outHumidity = data.data.outHumidity
		# console.log data.data, outTemp + '&deg; &nbsp; ' + outHumidity+'%'
		console.log outTemp, outHumidity
		$('#current').replaceWith render ->
			div '#current', style:'clear:both; float:left; position:relative; top:5%;
				width:100%; height:24%; font-size:175px', ->
				div style:'clear:both; float:left; margin:2% 0 2% 12%;
						color:white;', ->
					raw outTemp + '&deg;'
				div style:'float:right; margin:2% 7% 2% 0%;
						color:white;', ->
					raw outHumidity+'%'

	$.getJSON '/flash', (data) -> {flash, dateMS} = data

  # date = new Date()
  # date is based on server time when pill reminder enabled
	date = new Date +dateMS 

	dow  = date.getDay()
	dowStr = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][dow]
	$('#dow').css(fontSize: '140px').text dowStr

	hour = ['12', ' 1', ' 2', ' 3', ' 4', ' 5',
			' 6', ' 7', ' 8', ' 9', '10', '11'][date.getHours() % 12]
	mins = '' + date.getMinutes()
	if mins.length < 2 then mins = '0' + mins
	$('#time').html hour + ':' + mins

	month = date.getMonth() + 1
	day = date.getDate()  
	$('#date').text month + '/' + day

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
$('#dow').css color: dowColor

blockFlash = no

setInterval ->
  # console.log {blockFlash, flash}
  if not blockFlash
    if flash isnt 'no'
      if dowColor is 'white' then dowColor = '#ffffaa' else dowColor = 'white'
    else
      dowColor = 'white'
    $('#dow').css color: dowColor
, 1000

$ ->
	$('body').on 'click', '#dow', ->
		blockFlash = yes
		dowColor = 'red'
		$('#dow').css color: dowColor
		setTimeout ->
			dowColor = 'white'
			$('#dow').css color: dowColor
			blockFlash = no
			flash = 'no'
		, 1000
		$.get '/flash', clear: 1

	# refreshFore()
	refreshCurAndTime()

	dayTimeout = null

	$('body').on 'click', '#forecast', ->

		clrDayTimeout = ->
			dayOfs = 0
			refreshFore()
			if dayTimeout
				clearTimeout dayTimeout
				dayTimeout = null

		if dayTimeout then clearTimeout dayTimeout
		dayTimeout = setTimeout clrDayTimeout, 10 * 1000

		dayOfs++
		refreshFore()
