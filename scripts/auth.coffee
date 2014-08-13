# Description:
#   Auth allows you to assign roles to users which can be used by other scripts
#   to restrict access to Hubot commands
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_AUTH_ADMIN - A comma separate list of user IDs
#
# Commands:
#   hubot <user> has <role> role - Assigns a role to a user
#   hubot <user> doesn't have <role> role - Removes a role from a user
#   hubot what role does <user> have - Find out what roles are assigned to a specific user
#   hubot who has admin role - Find out who's an admin and can assign roles
#   hubot who am I? - returns name reference that hubot has to you
#   hubot what do you know about me? - returns the user object that is used to validate you
#   hubot can you fix my roles? - hubot tried to fix duplicated data
#
#
# Notes:
#   * Call the method: robot.auth.hasRole(msg.envelope.user,'<role>')
#   * returns bool true or false
#
#   * the 'admin' role can only be assigned through the environment variable
#   * roles are all transformed to lower case
#
#   * The script assumes that user IDs will be unique on the service end as to
#     correctly identify a user. Names were insecure as a user could impersonate
#     a user
#
# Author:
#   alexwilliamsca, tombell

module.exports = (robot) ->

  unless process.env.HUBOT_AUTH_ADMIN?
    robot.logger.warning 'The HUBOT_AUTH_ADMIN environment variable not set'

  if process.env.HUBOT_AUTH_ADMIN?
    admins = process.env.HUBOT_AUTH_ADMIN.split ','
  else
    admins = []

  class Auth
    hasRole: (user, roles) ->
      user = robot.brain.userForId(user.id)
      if user? and user.roles?
        roles = [roles] if typeof roles is 'string'
        for role in roles
          return true if role in user.roles
      return false

    usersWithRole: (role) ->
      users = []
      for own key, user of robot.brain.data.users
        if robot.auth.hasRole(msg.envelope.user, role)
          users.push(user)
      users
    getUserByName: ( name ) ->
      _user = null
      for own key, user of robot.brain.data.users
        if user.name is name
          _user = user
      _user

  robot.auth = new Auth

  # These are mainly for dubugging purposes
  robot.respond /who am i\?*$/i, (msg) ->
    msg.reply 'you are ' + msg.message.user.name.toString() + ' to me at least.'

  robot.respond /can you fix my roles\?$/i, ( msg ) ->
    user = msg.message.user
    name = user.name
    storedUser = robot.auth.getUserByName( name )

    if storedUser and user and storedUser.id isnt user.id
      success = null
      error = null
      try
        roles = robot.brain.data.users[ user.id ].roles or [];
        robot.brain.data.users[ user.id ].roles = roles.concat( storedUser.roles or [] )
        delete robot.brain.data.users[ storedUser.id ];
        success = true
      catch e
        success = null
        error = e

      if success
        msg.reply "Your all fixed up #{name}"
      else
        if error
          msg.reply "I made a mess: " + e.message
        else
          msg.reply "Sorry wasnt able to fix that for you"

    else
      msg.reply "It does not seem that your having any issues"

  robot.respond /what do you know about me\?*$/i, ( msg ) ->
    user = robot.auth.getUserByName( msg.message.user.name )
    if user
      msg.reply JSON.stringify( user, null, '\t' )
    else
      msg.reply 'Nothing your off the grid ;-)'


  robot.respond /@?(.+) (has) (["'\w: -_]+) (role)/i, (msg) ->
    name    = msg.match[1].trim()
    newRole = msg.match[3].trim().toLowerCase()

    unless name.toLowerCase() in ['', 'who', 'what', 'where', 'when', 'why']
      user = robot.auth.getUserByName( name )
      return msg.reply "#{name} does not exist" unless user?
      user.roles or= []

      if newRole in user.roles
        msg.reply "#{name} already has the '#{newRole}' role."
      else
        myRoles = msg.message.user.roles or []
        if "admin" in myRoles or msg.message.user.name in admins
          user.roles.push( newRole )
          msg.reply "Ok, #{name} has the '#{newRole}' role."
        else
          msg.reply "I dont have to listen to you, you're not admin"

  robot.respond /@?(.+) (doesn't have|does not have) (["'\w: -_]+) (role)/i, (msg) ->
    name    = msg.match[1].trim()
    newRole = msg.match[3].trim().toLowerCase()

    unless name.toLowerCase() in ['', 'who', 'what', 'where', 'when', 'why']

      user = robot.auth.getUserByName( name )
      return msg.reply "#{name} does not exist" unless user?
      user.roles or= []

      myRoles = msg.message.user.roles or []
      if "admin" in myRoles
        user.roles = (role for role in user.roles when role isnt newRole)
        msg.reply "Ok, #{name} doesn't have the '#{newRole}' role."
      else
          msg.reply "I dont have to listen to you, your not admin"

  robot.respond /(what role does|what roles does) @?(.+) (have)\?*$/i, (msg) ->
    name = msg.match[2].trim()
    user = robot.brain.userForName(name)
    return msg.reply "#{name} does not exist" unless user?
    user.roles or= []
    displayRoles = user.roles

    if user.id.toString() in admins
      displayRoles.push('admin') unless 'admin' in user.roles

    if displayRoles.length == 0
      msg.reply "#{name} has no roles."
    else
      msg.reply "#{name} has the following roles: #{displayRoles.join(', ')}."

  robot.respond /who has admin role\?*$/i, (msg) ->
    adminNames = []
    for admin in admins
      user = robot.brain.userForId(admin)
      unless robot.auth.hasRole(msg.envelope.user,'admin')
        adminNames.push user.name if user?

    if adminNames.length > 0
      msg.reply "The following people have the 'admin' role: #{adminNames.join(', ')}"
    else
      msg.reply "There are no people that have the 'admin' role."
