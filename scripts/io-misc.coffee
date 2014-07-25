module.exports = (robot) ->
	robot.hear /tired|too hard|to hard|upset|bored/i, (msg) ->
		msg.send "Slack Moar"
