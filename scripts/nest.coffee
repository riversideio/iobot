# Name:
#	 Nest
#
# Description:
#	 Control your nest thermostat.
#
# How:
# 	Once you have slackbot admin, give any user a role: hubot *username* has nest role
#
# Commands:
# 	hubot c/curr/current/room t/temp/temperature/status - Room temperature
# 	hubot status/st - Target temperature
# 	hubot sleep/zzz/away/goodnight/good night/off|die - Sleep
# 	hubot wake|wake up|wakeup|speak|up|rise|rise and shine - Wake
# 	hubot i'm here set nest - sets nest to your preferred temp

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
		msg.send "Nest temperature has been set to " + nest.ctof(new_temp) + 'ºF.'
		nest.setTemperature options.nest_id, new_temp


changeTemperatureTo = (toF, msg) ->
	nest.fetchStatus (data) ->
		toC = nest.ftoc(toF)
		nest.setTemperature options.nest_id, toC
		msg.send "Nest temperature has been set to " + nest.ctof(toC) + 'ºF.'


goToSleep = (toF, msg) ->
	nest.fetchStatus (data) ->
		toC = nest.ftoc(toF)
		nest.setTemperature options.nest_id, toC
		msg.send "Nest has entered away mode"


module.exports = (robot) ->
	# current room temperature
	robot.hear /nest (c|curr|current|room) (t|temp|temperature)/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			nest.fetchStatus (data) ->
				current_temp = data.shared[options.nest_id].current_temperature
				msg.send "Nest says it's " + nest.ctof(current_temp) + "ºF in the room."

	# nest target temperature
	robot.hear /nest (status|st)/i, (msg) ->
		nest.login options.login, options.password, (data) ->
			nest.fetchStatus (data) ->
				current_target = data.shared[options.nest_id].target_temperature
				msg.send "Nest is currently set to " + nest.ctof(current_target) + "ºF."

	# set temperature
	robot.hear /nest (s|set) (\d{2}).*/i, (msg) ->
		if 'nest' in msg.message.user.roles
			nest.login options.login, options.password, (data) ->
				changeTemperatureTo msg.match[2], msg
		else
			msg.reply "Please consult an admin to get access to Nest"

	# sleep // dependent upon nest away temperature
	robot.hear /nest (sleep|zzz|away|goodnight|good night|off|die)/i, (msg) ->
		if 'nest' in msg.message.user.roles
			nest.login options.login, options.password, (data) ->
				goToSleep 80, msg
		else
			msg.reply "Please consult an admin to get access to Nest"

	# wake and cool to 75
	robot.hear /nest (wake|wake up|wakeup|speak|up|rise|rise and shine)/i, (msg) ->
		if 'nest' in msg.message.user.roles
			nest.login options.login, options.password, (data) ->
				changeTemperatureTo 75, msg
		else
			msg.reply "Please consult an admin to get access to Nest"

	# set temp based of user pref
	robot.respond /i'm here set nest*$/i, (msg) ->
		if 'nest' in msg.message.user.roles
			if msg.message.user.tempPref
				nest.login options.login, options.password, (data) ->
					changeTemperatureTo msg.message.user.tempPref, msg
			else
				msg.reply 'no temperature preference is set for you\n' +
					'ask me to "set my nest preference to <degrees>"'
		else
			msg.reply 'Sorry this is only available to users with nest role'

	robot.respond /set my nest preference to ([0-9]+)*/i, (msg) ->
		if 'nest' in msg.message.user.roles
			temp = parseInt msg.match[ 1 ], 0;
			if typeof temp is 'number'
				# store
				robot.brain.data.users[msg.message.user.id].tempPref = temp;
				msg.reply 'I\'ve set your temperature preference to ' +  temp + 'degrees'
				# now set temp
				nest.login options.login, options.password, (data) ->
					changeTemperatureTo user.tempPref, msg
			else
				# bad type
				msg.reply 'Unable to set your temperature preference to ' + msg.match[1] + '. Try using a number'


	robot.router.get "/nest/status", (req, res) ->
		nest.login options.login, options.password, (data) ->
			nest.fetchStatus (data) ->
				current_target = data.shared[options.nest_id].target_temperature
				res.end "{\"current_temperature\": \"" + nest.ctof(current_target) + "\"}"
