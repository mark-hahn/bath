
phantomProxy = require("phantom-proxy")

module.exports = (url, cb) ->
  start = Date.now()
  
  # url = 'http://www.wunderground.com/weather-forecast/zmw:90807.3.99999'
  # url = 'https://www.google.com/search?q=weather+90807&oq=weather+90807&aqs=chrome..69i57j69i60l3.3899j0j1&sourceid=chrome&es_sm=93&ie=UTF-8'
  
  phantomProxy.create {}, (proxy) ->
    console.log 'url', url
    
    page = proxy.page

    page.on 'consoleMessage' (args...) ->
      console.log 'consoleMessage', args
    
    page.open url, ->
      page.waitForSelector "body", ->
        console.log "body tag present"
        
        page.evaluate ->
          indent = ''
          dump = (ele) ->
            indent += '  '
            console.log indent, ele.tagName, '#'+$(ele).attr('id'), '"'+$(ele).attr('class')+'"'
            $(ele).children().each ->
              dump @
            indent = indent[0..-3]
          $section = $ 'section.forecast'
          dump $section[0]
        , (args...) ->
          console.log 'dump result', args
          
          # page.render 'scrape.png', ->
          proxy.end ->
            console.log "done", Math.round (Date.now() - start) / 1000
            cb()
              