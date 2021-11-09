-- Route requests to a set of un-pooled application servers that are reserved
-- for debugging, based on the value of the X-Wikimedia-Debug header. The
-- X-Wikimedia-Debug header is made up of semicolon-separated fields. Each
-- field may consist of either an attribute name or an attribute=value pairs.
-- The code below extracts the value of the 'backend' attribute. For
-- backward-compatibility, if the header does not contain a well-formed
-- 'backend' attribute, then the entire header is used as the backend value.
--
-- See https://wikitech.wikimedia.org/wiki/X-Wikimedia-Debug

-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

function do_remap()
    local xwd = ts.client_request.header['X-Wikimedia-Debug']
    if not xwd then
        -- Stop immediately if no XWD header has been specified
        return TS_LUA_REMAP_NO_REMAP
    end

    local debug_map = {
        ["1"]                       = "mwdebug1001.eqiad.wmnet",
        ["mwdebug1001.eqiad.wmnet"] = "mwdebug1001.eqiad.wmnet",
        ["mwdebug1002.eqiad.wmnet"] = "mwdebug1002.eqiad.wmnet",
        ["mwdebug2001.codfw.wmnet"] = "mwdebug2001.codfw.wmnet",
        ["mwdebug2002.codfw.wmnet"] = "mwdebug2002.codfw.wmnet",
        ["k8s-experimental"]        = "mwdebug.discovery.wmnet",
    }

    local backend = string.match(xwd, 'backend=([%a%d%.-]+)')

    -- For backward-compatibility, if the header does not contain a
    -- well-formed 'backend' attribute, then the entire header is used as
    -- the backend value
    if not backend then
        backend = xwd
    end

    if debug_map[backend] then
        ts.client_request.set_url_host(debug_map[backend])
        -- Special case: mwdebug on kubernetes listens on port 4444
        if backend == "k8s-experimental" then
            ts.client_request.set_url_port(4444)
        end
        -- Skip the cache if XWD is valid
        ts.http.config_int_set(TS_LUA_CONFIG_HTTP_CACHE_HTTP, 0)

        return TS_LUA_REMAP_DID_REMAP_STOP
    else
        ts.http.set_resp(400, "x-wikimedia-debug-routing: no match found for the backend specified in X-Wikimedia-Debug")
        return TS_LUA_REMAP_NO_REMAP_STOP
    end
end
