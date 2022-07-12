---Metadata of the applcation (version info).
local metadata = {}

---Fetch the head commit id.
---By reading some files from the `.git` directory (hackish solution but portable).
---@return string|nil commitId `nil` when the `.git` directory doesn't exist or running in fused mode.
local function fetchCommitId()
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

---Read the content of the version.txt file if it exists.
---Check `docs/versioning.md`.
---@return string|nil versionTag `nil` when the file doesn't exists (considered a development/custom build).
local function readVersionFile()
    local content = love.filesystem.read('version.txt')
    return content
end

do
    local versionTag = readVersionFile() or fetchCommitId() or ''

    ---Get the version tag of the build.
    ---Read `docs/versioning.md` for more info on version tags and build type.
    ---@return string tag can be an empty string.
    function metadata.getVersionTag()
        return versionTag
    end
end

---Get the type of the build.
---Read `docs/versioning.md` for more info on version tags and build type.
---@return "release"|"pre-release"|"expermintal"|"development"|"custom" buildType
function metadata.getBuildType()
    local tag = metadata.getVersionTag()

    if tag:match('^%d+\\.%d+.%d+$') then
        return 'release'
    elseif tag:match('^%d+%.%d+%.%d+%-.+$') then
        return 'pre-release'
    elseif tag:match('^experiments%-%d%d%d%d%d%d%d%d%-%d%d%d$') then
        return 'expermintal'
    elseif tag:match('^%x+$') and #tag == 40 then
        return 'development'
    else
        return 'custom'
    end
end

return metadata
