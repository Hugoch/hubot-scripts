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
#   hubot monitor every <n> minutes - set hubot to monitor your URLs and warn you if their status change
#
# Notes:
#
#
# Author:
#   http://github.com/hugoch

_ = require("underscore")

module.exports = (robot) ->

    checkIntervalId = null

    check = (res, urls, data, silent=false) ->
        start_time = new Date().getTime()
        url = urls.pop()
        if url?
            robot.http(url)
                 .get() (err, resp, body) ->
                    end_time = new Date().getTime()
                    response_time = end_time - start_time
                    prev_status = robot.brain.get url
                    if err
                        data[url] = {status: "down", statusCode: 0, time: response_time, prev_status: prev_status}
                        prev_status = robot.brain.set url, "down"
                    else if resp.statusCode isnt 200 and resp.statusCode isnt 302
                        data[url] = {status: "down", statusCode: resp.statusCode, time: response_time, prev_status: prev_status}
                        prev_status = robot.brain.set url, "down"
                    else
                        data[url] = {status: "up", statusCode: 200, time: response_time, prev_status: prev_status}
                        prev_status = robot.brain.set url, "up"
                    check(res, urls, data, silent)
        else
            buff = []
            statusChanged = false
            for key, item of data
                if item.status != item.prev_status
                    statusChanged = true

            for key, item of data
                if item.status == "down"
                    buff.push(":red_circle: #{key} is #{item.status} (#{item.statusCode} in #{item.time}ms)")
                else
                    buff.push(":white_check_mark: #{key} is #{item.status} (#{item.statusCode} in #{item.time}ms)")

            if silent and statusChanged
                res.send "**Heads up**, I detected a change in your monitored URL status:\n" + buff.join("\n")
                return
            else if not silent
                res.send "Here is the status of monitored URLs:\n" + buff.join("\n")
                return
            return

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
        robot.brain.set url, "up"
        res.reply "I'm now monitoring *" + url + "*"

    robot.respond /stop monitoring (.*)/i, (res)->
        url = res.match[1]
        urls = robot.brain.get "statusUrlList"
        urls ?= []
        index = urls.indexOf(url)
        if index != -1
            urls.splice(index, 1)
            robot.brain.set "statusUrlList", urls
            robot.brain.set url, ""
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

    robot.respond /monitor every ([0-9]+) minute(.*)/i, (res)->
        interval = parseInt(res.match[1])
        if checkIntervalId?
            clearInterval(checkIntervalId)
        checkIntervalId = setInterval () ->
            urls = robot.brain.get "statusUrlList"
            urls ?= []
            check(res, _.clone(urls), {}, true)
        , interval * 60 * 1000
        res.send "I'm now monitoring your URLs every " + interval.toString() + " minutes."

    robot.respond /stop monitoring/i, (res)->
        if checkIntervalId?
            clearInterval(checkIntervalId)
            res.send "I'm not automatically monitoring anymore. Do it yourself!"
        else
            res.send "Whaaaat? I'm not monitoring anything."