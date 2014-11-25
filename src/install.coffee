###
    install.coffee
    cd /apps/bath
    service start
###

fs      = require 'fs'
Service = require("node-windows").Service

op = process.argv[2] ? 'start'
if op not in ['start', 'stop'] then console.log 'bad arg:', op; return

if fs.exists '/apps/bath/lib/server-released.js'
	fs.unlinkSync '/apps/bath/lib/server-released.js'

fs.createReadStream('/apps/bath/lib/server.js').
	pipe fs.createWriteStream '/apps/bath/lib/server-released.js'

svc = new Service 
	name: 			"BATH"
	description: 	"Bathroom Display"
	script: 		"C:/apps/bath/lib/server-released.js"

svc.on "install", -> 
	console.log 'BATH Service Installed'
	
	svc.start()
	console.log 'BATH Service Started'
	console.log "The service exists: ", svc.exists

svc.on "uninstall", ->
	console.log "BATH Service Uninstalled"
	console.log "The service exists: ", svc.exists
		
	if op is 'start' then svc.install()

if op is 'stop' and svc.exists
	svc.uninstall()
else if op is 'start'
	svc.install()
else
	console.log 'bath already stopped, nothing to do.'

