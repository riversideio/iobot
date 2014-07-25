# Description:
#	 Control your nest thermostat.
#
# Commands:
#	 hubot how (warm|cold) is it - current temperature
#	 hubot it's warm - set the nest 1 degree Fahrenheit lower
#	 hubot it's cold - set the nest 1 degree Fahrenheit higher
#	 hubot nest status - current nest setting

# https://github.com/kasima/nesting
nest = require('nesting')

# Be sure to set the following environment variables

options =
	login:		process.env.NEST_LOGIN
	password: process.env.NEST_PASSWORD
	nest_id:	process.env.NEST_ID

changeTemperatureBy = (byF, msg) ->
	nest.fetchStatus (data) ->
		byC = (5/9) * byF
		current_temp = data.shared[options.nest_id].target_temperature
		new_temp = current_temp + byC
		msg.send "I've set the nest to " + nest.ctof(new_temp) + ' degrees for you.'
		nest.setTemperature options.nest_id, new_temp

module.exports = (robot) ->
	robot.respond /how (warm|cold) is it/i, (msg) ->
		msg.send("Let me check on that...")
		nest.login options.login, options.password, (data) ->
			nest.fetchStatus (data) ->
				current_temp = data.shared[options.nest_id].current_temperature
				msg.send "It's currently " + nest.ctof(current_temp) + " degrees in here."

	robot.respond /it's(.*) (hot|warm)/i, (msg) ->
		msg.send("It's just me")
		nest.login options.login, options.password, (data) ->
			changeTemperatureBy -5, msg

	robot.respond /it's(.*) cold/i, (msg) ->
		msg.send("I'm on it...")
		nest.login options.login, options.password, (data) ->
			changeTemperatureBy +3, msg

	robot.respond /nest status/i, (msg) ->
		msg.send("Checking...")
		#msg.send(options.login)
		#msg.send(options.password)
		#msg.send(options.nest_id)
		nest.login options.login, options.password, (data) ->
			nest.fetchStatus (data) ->
				current_target = data.shared[options.nest_id].target_temperature
				msg.send "The nest is currently set to " + nest.ctof(current_target) + " degrees."
