local _M = {}

function _M.check_comment(pattern, errorMessage)

    ngx.req.read_body()

    local req = ngx.req.get_body_data()
    if req == nil then
        return
    end

    local commentNode = [[<crs:comment>(.*)</crs:comment>]]
    local commitMessage
    if req:match([[name="DevDepot_commitObjects"]]) ~= nil then
        commitMessage = req:match(commentNode)
    elseif req:match([[DevDepot_changeVersion]]) ~= nil then
        local newVersion = req:match([[<crs:newVersion>(.*)</crs:newVersion>]])
        if newVersion == nil then
            return
        end
        commitMessage = newVersion:match(commentNode)
    else
        return
    end

    -- проверка на пустой комментарий
    if commitMessage == nil then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.header.content_type = 'text/plain; charset=utf-8'
        ngx.say("ОТСУТСТВУЕТ КОММЕНТАРИЙ")
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    -- проверка на соответствие паттерну
    if pattern ~= nil then
        local rex = require('rex_pcre')
        local captures = rex.match(commitMessage, pattern)
        if captures == nil then
            ngx.status = ngx.HTTP_BAD_REQUEST
            ngx.header.content_type = 'text/plain; charset=utf-8'
            ngx.say(errorMessage)
            ngx.exit(ngx.HTTP_BAD_REQUEST)
        end
    end

    -- проверка на соответствие статуса задачи в Jira
    -- Паттерн для номера задачи
    local task_key_pattern = [[^BUH-\d{1,8}\b]]
    -- Список валидных статусов jira
    local validStatuses = Set { "MFG_IN PROGRESS", "MFG_Test", "MFG_Need To Correct"}
    
    local task = rex.match(captures, task_key_pattern) 
    local jira_check = require("v8.jira-check")
    local status = jira_check.get_task_status(task)
   

    if not validStatuses[status] then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.header.content_type = 'text/plain; charset=utf-8'
        ngx.say("Задача"+task+" не прошла проверку в Jira!")
        ngx.say("Помещать в хранилище можно только в статусах:")
        for _,v in pairs(validStatuses) do
            ngx.say("- "+ v) 
        end
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end 
    
end

return _M
