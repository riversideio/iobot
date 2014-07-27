# Hubot


Add any script to the /scripts, and add any dependencies to package.json

iobot
=====

Hubot for Riverside.io co-twerking space

Updating iobot:
```
iobot is on a heroku server. Ask someone for permission if you don't have it.
- Push code to heroku
- Restart heroku server
- $ heroku ps:scale web=1
```
Roles
=====
Checking for a certail role is easy!
We can get the user's role before executing any code by checking inside the ***msg*** object
```
  robot.hear /nest (s|set) (\d{2}).*/i, (msg) ->
    if 'nest' in msg.message.user.roles
      // change nest temperature
    else
      // talk to an admin
```

Setting a role is also easy! (Must be admin)
```
iobot *username* has nest role
>> Ok, *username* has the 'nest' role.

iobot *username* doesn't have nest role
>> Ok, *username* doesn't have 'nest' role.
```
