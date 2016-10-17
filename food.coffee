# Description:
#   Gives a link to the restaurant menu
#
# Configuration:
#   HUBOT_RESTAURANT_LINK
#
# Commands:
#   hubot food - prints the restaurant menu
#
# Author:
#   http://github.com/hugoch

module.exports = (robot) ->

    gifs = ["http://i.giphy.com/OrHFWUm6CNnFu.gif", "http://i.giphy.com/GnCc88zZhSVUc.gif", "http://i.giphy.com/rjN9e4I4mgspy.gif",
            "http://i.giphy.com/7oUdj7cAkXVfi.gif", "http://i.giphy.com/ZeB4HcMpsyDo4.gif"]
    robot.respond /food/i, (res)->
        link = process.env.HUBOT_RESTAURANT_LINK
        unless link?
                res.reply "Missing HUBOT_RESTAURANT_LINK in environment: please set and try again."
                return
        res.reply res.random gifs
        res.reply "Here is your food: " + link