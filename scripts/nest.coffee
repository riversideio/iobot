# Name:
#	 Nest
#
# Description:
#	 Control your nest thermostat.
#
# Commands:
	# hubot c/curr/current/room t/temp/temperature/status - Room temperature
	# hubot status/st - Target temperature
	# hubot sleep/zzz/away/goodnight/good night/off|die - Sleep
	# hubot wake|wake up|wakeup|speak|up|rise|rise and shine Wake
nest = require('nesting')

# Be sure to set the following environment variables
options =
	 login: process.env.NEST_LOGIN
	 password: process.env.NEST_PASSWORD
	 nest_id:	process.env.NEST_ID

changeTemperatureBy = (byF, msg) ->
	nest.fetchStatus (data) ->
		byC = (5/9) * byF
		current_temp = data.shared[options.nest_id].target_temperature
		new_temp = current_temp + byC
		msg.send "Nest temperature has been set to " + nest.ctof(new_temp) + 'ºF'
		nest.setTemperature options.nest_id, new_temp


changeTemperatureTo = (toF, msg) ->
	nest.fetchStatus (data) ->
		toC = nest.ftoc(toF)
		nest.setTemperature options.nest_id, toC
		msg.send "Nest temperature has been set to " + nest.ctof(toC) + 'ºF'


goToSleep = (toF, msg) ->
	nest.fetchStatus (data) ->
		toC = nest.ftoc(toF)
		nest.setTemperature options.nest_id, toC
		msg.send "Nest has entered away mode"



module.exports = (robot) ->
	# current room temperature
	robot.hear /nest (c|curr|current|room) (t|temp|temperature)/i, (msg) ->
		if 'nest' in msg.message.user.roles		
			nest.login options.login, options.password, (data) ->
				nest.fetchStatus (data) ->
					current_temp = data.shared[options.nest_id].current_temperature
					msg.send "Nest says it's " + nest.ctof(current_temp) + "ºF in the room."
		else
			msg.reply "Please consult an admin to get access to this"

	# nest target temperature
	robot.hear /nest (status|st)/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			nest.fetchStatus (data) ->
				current_target = data.shared[options.nest_id].target_temperature
				msg.send "Nest is currently set to " + nest.ctof(current_target) + "ºF."

	# set temperature
	robot.hear /nest (s|set) (\d{2}).*/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			changeTemperatureTo msg.match[2], msg

	# sleep // dependent upon nest away temperature
	robot.hear /nest (sleep|zzz|away|goodnight|good night|off|die)/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			goToSleep 80, msg

	# wake and cool to 75
	robot.hear /nest (wake|wake up|wakeup|speak|up|rise|rise and shine)/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			changeTemperatureTo 75, msg

	robot.router.get "/nest/status", (req, res) ->
		nest.login options.login, options.password, (data) ->
			nest.fetchStatus (data) ->
				current_target = data.shared[options.nest_id].target_temperature
				res.end "{\"current_temperature\": \"" + nest.ctof(current_target) + "\"}"
