local _M = {}

local function create_list(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

function _M.check_comment(pattern, errorMessage)
    ngx.req.read_body()

    local req = ngx.req.get_body_data()
    if req == nil then
        return
    end

    local commentNode = [[<crs:comment>(.*)</crs:comment>]]
    local commentUserNode = [[<crs:auth user=(.*)password=]]
    local commitMessage
    local repo_user = ""
    local rex
    local captures
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

    -- Найдем пользователя хранилища

    local function isempty(s)
        return s == nil or s == ''
    end

    repo_user = req:match(commentUserNode)  -- пользователь хранилища
    if isempty(repo_user) then
        repo_user = "untitled"
    end

    repo_user = repo_user:gsub('"', '')
    repo_user = repo_user:gsub(' ', '')

    -- проверка на пустой комментарий
    if commitMessage == nil then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.header.content_type = 'text/plain; charset=utf-8'
        ngx.say("YOU SHALL NOT PASS!!!")
        ngx.say("Отсутствует комментарий для помещения в хранилище.")
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    -- проверка на соответствие паттерну
    if pattern ~= nil then
        rex = require('rex_pcre')
        captures = rex.match(commitMessage, pattern)
        if captures == nil then
            ngx.status = ngx.HTTP_BAD_REQUEST
            ngx.header.content_type = 'text/plain; charset=utf-8'
            ngx.say(errorMessage)
            ngx.exit(ngx.HTTP_BAD_REQUEST)
        end
    end

    -- проверка на наличие пользователя

    rex = require('rex_pcre')
    captures = rex.match(commitMessage, [[@zetasoft.ru]])
    if (repo_user == "stage" or repo_user == "release") and captures == nil then
        errorMessage = 
[[
Не указан пользователь хранилища в комментарии при помещении из stage или release
Добавьте в комментарий свой логин от хранилища в формате @zetasoft.ru
]]
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.header.content_type = 'text/plain; charset=utf-8'
        ngx.say("YOU SHALL NOT PASS!!!")
        ngx.say(errorMessage)
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
end

return _M
