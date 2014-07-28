# Description:
# io specific shit
#
# Dependencies:
#   request
#
# Configuration:
#   IO_API - Points toward bento api
#
# Commands:
#   what are the plans? - shows a list of plans
#

module.exports = ( robot ) ->

    io = (require './lib/io-sdk.js')( process.env.IO_API )

    mapName = ( plan ) ->
        plan.name + ' - ' + plan.interval + 'ly'

    #make it available every where 
    robot.io = io

    robot.hear /tired|too hard|to hard|upset|bored/i, (msg) ->
        msg.send "Slack Moar"

    robot.hear /what are the plans\?*$/, (msg) ->
        io.plans.all ( err, plans ) ->
            if err
                msg.reply err.message
                return
            msg.reply ( plans.plans.map mapName ).join '\n'
            plans
