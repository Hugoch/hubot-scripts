# Description:
#   Checks the status of services
#
# Configuration:
#
#
# Commands:
#   hubot monitor URL - add an URL to monitor
#   hubot stop monitoring URL - stop monitoring the given URL
#   hubot what are you monitoring - show list of monitored URLs
#   hubot status - retrieve status of monitored URLs
#
# Notes:
#
#
# Author:
#   http://github.com/hugoch

_ = require("underscore")

module.exports = (robot) ->

    check = (res, urls, data) ->
        start_time = new Date().getTime()
        url = urls.pop()
        if url?
            robot.http(url)
                 .get() (err, resp, body) ->
                    end_time = new Date().getTime()
                    response_time = end_time - start_time
                    if err
                        data[url] = {status: "down", statusCode: 0, time: response_time}
                    else if resp.statusCode isnt 200 and resp.statusCode isnt 302
                        data[url] = {status: "down", statusCode: resp.statusCode, time: response_time}
                    else
                        data[url] = {status: "up", statusCode: 200, time: response_time}
                    check(res, urls, data)
        else
            buff = []
            for key, item of data
                if item.status == "down"
                    buff.push(":red_circle: #{key} is #{item.status} (#{item.statusCode} in #{item.time}ms)")
                else
                    buff.push(":white_check_mark: #{key} is #{item.status} (#{item.statusCode} in #{item.time}ms)")
            res.send "Here is the status of monitored URLs:\n" + buff.join("\n")

    robot.respond /monitor url (.*)/i, (res)->
        url = res.match[1]
        urls = robot.brain.get 'statusUrlList'
        urls ?= []
        for item in urls
            if item == url
                res.reply "I'm already monitoring *" + url + "*"
                return
        urls.push(url)
        robot.brain.set "statusUrlList", urls
        res.reply "I'm now monitoring *" + url + "*"

    robot.respond /stop monitoring (.*)/i, (res)->
        url = res.match[1]
        urls = robot.brain.get "statusUrlList"
        urls ?= []
        index = urls.indexOf(url)
        if index != -1
            urls.splice(index, 1)
            robot.brain.set "statusUrlList", urls
            res.reply "I'm not monitoring *" + url + "* anymore."
        else
            res.reply "I'm not monitoring *" + url + "*, check your syntax dude!"

    robot.respond /what are you monitoring/i, (res)->
        urls = robot.brain.get "statusUrlList"
        urls ?= []
        console.log(urls)

        if urls.length > 0
            res.reply "Here's the list of monitored URLs:\n\n" + urls.join('\n')
        else
            res.reply "I'm currently not monitoring anything. Why don't you add some URLs?"

    robot.respond /status/i, (res)->
        urls = robot.brain.get "statusUrlList"
        urls ?= []
        if urls.length > 0
            check(res, _.clone(urls), {})
        else
            res.reply "I'm currently not monitoring anything. Why don't you add some URLs?"