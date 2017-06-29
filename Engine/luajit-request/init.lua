--[[
LuaJIT-Request
Lucien Greathouse
Wrapper for LuaJIT-cURL for easy HTTP(S) requests.

Copyright (c) 2016 Lucien Greathouse

This software is provided 'as-is', without any express
or implied warranty. In no event will the authors be held
liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, andto alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
claim that you wrote the original software. If you use this software
in a product, an acknowledgment in the product documentation would be
appreciated but is not required.

2. Altered source versions must be plainly marked as such, and must
not be misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.
]]

local path = (...):gsub("%.init$", ""):match("%.?(.-)$") .. "."

local ffi = require("ffi")
local curl = require(path .. "luajit-curl")
local request

local function url_encode(str)
	if (str) then
		str = str:gsub("\n", "\r\n")
		str = str:gsub("([^%w %-%_%.%~])", function(c)
			return string.format ("%%%02X", string.byte(c))
		end)
		str = str:gsub(" ", "%%20")
	end
	return str
end

local function cookie_encode(str, name)
	str = str:gsub("[,;%s]", "")

	if (name) then
		str = str:gsub("=", "")
	end

	return str
end

local auth_map = {
	BASIC = ffi.cast("long", curl.CURLAUTH_BASIC),
	DIGEST = ffi.cast("long", curl.CURLAUTH_DIGEST),
	NEGOTIATE = ffi.cast("long", curl.CURLAUTH_NEGOTIATE)
}

local errors = {
	unknown = 0,
	timeout = 1,
	connect = 2,
	resolve_host = 3
}

local code_map = {
	[curl.CURLE_OPERATION_TIMEDOUT] = {
		errors.timeout, "Connection timed out"
	},
	[curl.CURLE_COULDNT_RESOLVE_HOST] = {
		errors.resolve_host, "Couldn't resolve host"
	},
	[curl.CURLE_COULDNT_CONNECT] = {
		errors.connect, "Couldn't connect to host"
	}
}

request = {
	error = errors,

	version = "2.4.0",
	version_major = 2,
	version_minor = 4,
	version_patch = 0,

	--[[
		Send an HTTP(S) request to the URL at 'url' using the HTTP method 'method'.
		Use the 'args' parameter to optionally configure the request:
			- method: HTTP method to use. Defaults to "GET", but can be any HTTP verb like "POST" or "PUT"
			- headers: Dictionary of additional HTTP headers to send with request
			- data: Dictionary or string to send as request body
			- cookies: Dictionary table of cookies to send
			- timeout: How long to wait for the connection to be made before giving up
			- allow_redirects: Whether or not to allow redirection. Defaults to true
			- body_stream_callback: A method to call with each piece of the response body.
			- header_stream_callback: A method to call with each piece of the resulting header.
			- transfer_info_callback: A method to call with transfer progress data.
			- auth_type: Authentication method to use. Defaults to "none", but can also be "basic", "digest" or "negotiate"
			- username: A username to use with authentication. 'auth_type' must also be specified.
			- password: A password to use with authentication. 'auth_type' must also be specified.
			- files: A dictionary of file names to their paths on disk to upload via stream.

		If both body_stream_callback and header_stream_callback are defined, a boolean true will be returned instead of the following object.

		The return object is a dictionary with the following members:
			- code: The HTTP status code the response gave. Will not exist if header_stream_callback is defined above.
			- body: The body of the response. Will not exist if body_stream_callback is defined above.
			- headers: A dictionary of headers and their values. Will not exist if header_stream_callback is defined above.
			- headers_raw: A raw string containing the actual headers the server sent back. Will not exist if header_stream_callback is defined above.
			- set_cookies: A dictionary of cookies given by the "Set-Cookie" header from the server. Will not exist if the server did not set any cookies.

	]]
	send = function(url, args)
		local handle = curl.curl_easy_init()
		local header_chunk
		local out_buffer
		local headers_buffer
		args = args or {}

		local callbacks = {}
		local gc_handles = {}

		curl.curl_easy_setopt(handle, curl.CURLOPT_URL, url)
		curl.curl_easy_setopt(handle, curl.CURLOPT_SSL_VERIFYPEER, 1)
		curl.curl_easy_setopt(handle, curl.CURLOPT_SSL_VERIFYHOST, 2)

		if (args.method) then
			local method = string.upper(tostring(args.method))

			if (method == "GET") then
				curl.curl_easy_setopt(handle, curl.CURLOPT_HTTPGET, 1)
			elseif (method == "POST") then
				curl.curl_easy_setopt(handle, curl.CURLOPT_POST, 1)
			else
				curl.curl_easy_setopt(handle, curl.CURLOPT_CUSTOMREQUEST, method)
			end
		end

		if (args.headers) then
			for key, value in pairs(args.headers) do
				header_chunk = curl.curl_slist_append(header_chunk, tostring(key) .. ":" .. tostring(value))
			end

			curl.curl_easy_setopt(handle, curl.CURLOPT_HTTPHEADER, header_chunk)
		end

		if (args.auth_type) then
			local auth = string.upper(tostring(args.auth_type))

			if (auth_map[auth]) then
				curl.curl_easy_setopt(handle, curl.CURLOPT_HTTPAUTH, auth_map[auth])
				curl.curl_easy_setopt(handle, curl.CURLOPT_USERNAME, tostring(args.username))
				curl.curl_easy_setopt(handle, curl.CURLOPT_PASSWORD, tostring(args.password or ""))
			elseif (auth ~= "NONE") then
				error("Unsupported authentication type '" .. auth .. "'")
			end
		end

		if (args.body_stream_callback) then
			local callback = ffi.cast("curl_callback", function(data, size, nmeb, user)
				args.body_stream_callback(ffi.string(data, size * nmeb))
				return size * nmeb
			end)

			table.insert(callbacks, callback)

			curl.curl_easy_setopt(handle, curl.CURLOPT_WRITEFUNCTION, callback)
		else
			out_buffer = {}

			local callback = ffi.cast("curl_callback", function(data, size, nmeb, user)
				table.insert(out_buffer, ffi.string(data, size * nmeb))
				return size * nmeb
			end)

			table.insert(callbacks, callback)

			curl.curl_easy_setopt(handle, curl.CURLOPT_WRITEFUNCTION, callback)
		end

		if (args.header_stream_callback) then
			local callback = ffi.cast("curl_callback", function(data, size, nmeb, user)
				args.header_stream_callback(ffi.string(data, size * nmeb))
				return size * nmeb
			end)

			table.insert(callbacks, callback)

			curl.curl_easy_setopt(handle, curl.CURLOPT_HEADERFUNCTION, callback)
		else
			headers_buffer = {}

			local callback = ffi.cast("curl_callback", function(data, size, nmeb, user)
				table.insert(headers_buffer, ffi.string(data, size * nmeb))
				return size * nmeb
			end)

			table.insert(callbacks, callback)

			curl.curl_easy_setopt(handle, curl.CURLOPT_HEADERFUNCTION, callback)
		end

		if (args.transfer_info_callback) then
			local callback = ffi.cast("curl_xferinfo_callback", function(client, dltotal, dlnow, ultotal, ulnow)
				args.transfer_info_callback(tonumber(dltotal), tonumber(dlnow), tonumber(ultotal), tonumber(ulnow))
				return 0
			end)

			table.insert(callbacks, callback)

			curl.curl_easy_setopt(handle, curl.CURLOPT_NOPROGRESS, 0)
			curl.curl_easy_setopt(handle, curl.CURLOPT_XFERINFOFUNCTION, callback)
		end

		if (args.follow_redirects == nil) then
			curl.curl_easy_setopt(handle, curl.CURLOPT_FOLLOWLOCATION, true)
		else
			curl.curl_easy_setopt(handle, curl.CURLOPT_FOLLOWLOCATION, not not args.follow_redirects)
		end

		if (args.data) then
			if (type(args.data) == "table") then
				local buffer = {}
				for key, value in pairs(args.data) do
					table.insert(buffer, ("%s=%s"):format(url_encode(key), url_encode(value)))
				end

				curl.curl_easy_setopt(handle, curl.CURLOPT_POSTFIELDS, table.concat(buffer, "&"))
			else
				curl.curl_easy_setopt(handle, curl.CURLOPT_POSTFIELDS, tostring(args.data))
			end
		end

		local post
		if (args.files) then
			post = ffi.new("struct curl_httppost*[1]")
			local lastptr = ffi.new("struct curl_httppost*[1]")

			for key, value in pairs(args.files) do
				local file = ffi.new("char[?]", #value, value)

				table.insert(gc_handles, file)

				local res = curl.curl_formadd(
					post, lastptr,
					ffi.new("int", curl.CURLFORM_COPYNAME), key,
					ffi.new("int", curl.CURLFORM_FILE), file,
					ffi.new("int", curl.CURLFORM_END)
				)
			end

			curl.curl_easy_setopt(handle, curl.CURLOPT_HTTPPOST, post[0])
		end

		-- Enable the cookie engine
		curl.curl_easy_setopt(handle, curl.CURLOPT_COOKIEFILE, "")

		if (args.cookies) then
			local cookie_out

			if (type(args.cookies) == "table") then
				local buffer = {}
				for key, value in pairs(args.cookies) do
					table.insert(buffer, ("%s=%s"):format(cookie_encode(key, true), cookie_encode(value)))
				end

				cookie_out = table.concat(buffer, "; ")
			else
				cookie_out = tostring(args.cookies)
			end

			curl.curl_easy_setopt(handle, curl.CURLOPT_COOKIE, cookie_out)
		end

		if (tonumber(args.timeout)) then
			curl.curl_easy_setopt(handle, curl.CURLOPT_CONNECTTIMEOUT, tonumber(args.timeout))
		end

		local code = curl.curl_easy_perform(handle)

		if (code ~= curl.CURLE_OK) then
			local num = tonumber(code)

			if (code_map[num]) then
				return false, code_map[num][1], code_map[num][2]
			end

			return false, request.error.unknown, "Unknown error", num
		end

		local out

		if (out_buffer or headers_buffer) then
			local headers, status, parsed_headers, raw_cookies, set_cookies

			if (headers_buffer) then
				headers = table.concat(headers_buffer)
				status = headers:match("%s+(%d+)%s+")

				parsed_headers = {}

				for key, value in headers:gmatch("\n([^:]+): *([^\r\n]*)") do
					parsed_headers[key] = value
				end
			end

			local cookielist = ffi.new("struct curl_slist*[1]")
			curl.curl_easy_getinfo(handle, curl.CURLINFO_COOKIELIST, cookielist)
			if cookielist[0] ~= nil then
				raw_cookies, set_cookies = {}, {}
				local cookielist = ffi.gc(cookielist[0], curl.curl_slist_free_all)
				local cookie = cookielist

				repeat
					local raw = ffi.string(cookie[0].data)
					table.insert(raw_cookies, raw)

					local domain, subdomains, path, secure, expiration, name, value = raw:match("^(.-)\t(.-)\t(.-)\t(.-)\t(.-)\t(.-)\t(.*)$")
					set_cookies[name] = value
					cookie = cookie[0].next
				until cookie == nil
			end

			out = {
				body = table.concat(out_buffer),
				headers = parsed_headers,
				raw_cookies = raw_cookies,
				set_cookies = set_cookies,
				code = status,
				raw_headers = headers
			}
		else
			out = true
		end

		curl.curl_easy_cleanup(handle)
		curl.curl_slist_free_all(header_chunk)

		if (post) then
			curl.curl_formfree(post[0])
		end
		gc_handles = {}

		for i, v in ipairs(callbacks) do
			v:free()
		end

		return out
	end,

	init = function()
		curl.curl_global_init(curl.CURL_GLOBAL_ALL)
	end,

	close = function()
		curl.curl_global_cleanup()
	end
}

request.init()

return request
