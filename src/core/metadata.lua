---Metadata of the applcation (version info).
local metadata = {}

---Fetches the head commit id.
---By reading some files from the `.git` directory (hackish solution but portable).
---@return string|nil commitId commit id. `nil` when the `.git` directory doesn't exist or running in fused mode.
function metadata.fetchCommitId()
    if love.filesystem.isFused() then return end

    local baseDirectory = love.filesystem.getSourceBaseDirectory()

    -- The `io` library has to be used instead of `love.filesystem`
    -- because the git directory is out from the root directory (`src`).

    local headFile = io.open(baseDirectory .. '/.git/HEAD')
    if not headFile then return end

    local headContent = headFile:read()
    headFile:close()

    local referencePath = assert(assert(headContent):match('^ref: (.*)$'), 'failed to parse reference path')
    local referenceFile = assert(io.open(baseDirectory .. '/.git/' .. referencePath))
    local commitId = referenceFile:read()
    referenceFile:close()

    return assert(commitId, 'failed to resolve commitId')
end

return metadata
