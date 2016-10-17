# Description:
#   Deploys an application using Deploy software
#
# Configuration:
#   HUBOT_DEPLOY_SERVER HUBOT_DEPLOY_KEY_app
#
# Commands:
#   hubot deploy APP - deploy the APP application if it exists
#
# Notes:
#   Deploy server must be up and running. Set HUBOT_DEPLOY_KEY_app with the deployment key.
#
# Author:
#   http://github.com/hugoch

module.exports = (robot) ->

    deployServer= process.env.HUBOT_DEPLOY_SERVER
    deployKeys = process.env.HUBOT_DEPLOY_KEYS

    robot.respond /deploy (.*)/i, (res)->
        unless deployServer?
            res.reply "Missing HUBOT_DEPLOY_SERVER in environment: please set and try again."
            return
        app = res.match[1]
        appKey = process.env['HUBOT_DEPLOY_KEY_' + app]
        unless appKey?
            res.reply "I don't know this application. Please set HUBOT_DEPLOY_KEY_" + app + " and try again."
            return
        robot.http(deployServer + '/api/deploy/' + appKey)
             .get() (err, resp, body) ->
                if err or resp.statusCode isnt 200
                    res.reply "Deployment server gave me an error :(."
                    return
                res.reply "You got neat code? Deployment of " + app + " started."