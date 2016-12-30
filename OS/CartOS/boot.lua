local ok, err = coroutine.yield("GPU:print","Hello World")
if not ok then error(err) end