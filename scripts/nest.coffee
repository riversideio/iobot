# Name:
#	 Nest
#
# Description:
#	 Control your nest thermostat.
#
# Commands:
	# hubot (c|curr|current|room) (t|temp|temperature|status)
	# hubot (status|st)
	# hubot (sleep|zzz|away|goodnight|good night|off|die)
	# hubot (wake|wake up|wakeup|speak|up|rise|rise and shine)
#
#	https://github.com/m2mIO/2lemetry-hubot/blob/master/scripts/nest.coffee
# https://github.com/kasima/nesting
#
nest = require('nesting')

# Be sure to set the following environment variables
options =
	 login: process.env.nest_LOGIN
	 password: process.env.nest_PASSWORD
	 nest_id:	process.env.nest_ID

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
    msg.send "Nest temperature has been set to " + nest.ctof(toC) + 'ºF'
    nest.setTemperature options.nest_id, toC


module.exports = (robot) ->
	# current room temperature
	robot.respond /nest (c|curr|current|room) (t|temp|temperature|status)/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			nest.fetchStatus (data) ->
				current_temp = data.shared[options.nest_id].current_temperature
				msg.send "Nest says it's " + nest.ctof(current_temp) + "ºF."

	# nest target temperature
	robot.respond /nest (status|st)/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			nest.fetchStatus (data) ->
				current_target = data.shared[options.nest_id].target_temperature
				msg.send "The nest is currently set to " + nest.ctof(current_target) + "ºF."

  # set temperature
	robot.respond /nest (s|set) (\d{2}).*/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			changeTemperatureTo msg.match[2], msg

  # sleep // dependent upon nest away temperature
	robot.respond /nest (sleep|zzz|away|goodnight|good night|off|die)/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			changeTemperatureTo 80, msg

  # wake and cool to 75
	robot.respond /nest (wake|wake up|wakeup|speak|up|rise|rise and shine)/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			changeTemperatureTo 75, msg

	robot.router.get "/nest/status", (req, res) ->
		nest.login options.login, options.password, (data) ->
			nest.fetchStatus (data) ->
				current_target = data.shared[options.nest_id].target_temperature
				res.end "{\"current_temperature\": \"" + nest.ctof(current_target) + "\"}"
