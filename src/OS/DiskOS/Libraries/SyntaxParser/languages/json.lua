--JSON syntax parser

--Push the current state into the states stack
local function pushState(state)
    state.stack[#state.stack + 1] = state.current
end

--Pop the current state from the states stack
local function popState(state)
    state.current = state.stack[#state.stack]
    state.stack[#state.stack] = nil
end

--Set the current state into the error state
local function errorState(state)
    state.current = {
        tokenizer = "error",
        stage = 0
    }

    return "error"
end

--The tokenizer
local function token(stream, state)
    local current = state.current
    local stage = current.stage

    --Debug prints, cause much slowdown!
    --cprint("TOKENIZER",current.tokenizer)
    --cprint("STAGE",stage,"STACK",#state.stack)

    --Parse nothing
    if current.tokenizer == "none" then
        stream:skipToEnd()
        return "text"
    
    --Parse everything as error
    elseif current.tokenizer == "error" then
        stream:skipToEnd()
        return "error"

    --Parse a value block
    elseif current.tokenizer == "value" then
        --Parse whitespace
        if stage == 0 then
            current.stage = 1 --Next stage after poping from stack

            pushState(state)

            state.current = {
                tokenizer = "whitespace",
                stage = 0
            }

            return "text"
        
        --Identifiy the value type and parse it
        elseif stage == 1 then
            current.stage = 2 --Next stage after poping from stack

            pushState(state)

            local char = stream:peek() --What's the next character ?

            --String
            if char == '"' then
                state.current = {
                    tokenizer = "string",
                    stage = 0
                }
            --Number
            elseif char:match("[%-0123456789]") then
                state.current = {
                    tokenizer = "number",
                    stage = 0
                }
            --Object
            elseif char == "{" then
                state.current = {
                    tokenizer = "object",
                    stage = 0
                }
            --Array
            elseif char == "[" then
                state.current = {
                    tokenizer = "array",
                    stage = 0
                }
            --Boolean & Null
            elseif stream:match("true") or stream:match("false") or stream:match("null") then
                popState(state)
                current.stage = 2
                return "keyword"
            --Error
            else
                current.stage = 3 --Skip to last stage
                return errorState(state)
            end

            return "text"
        
        --Trailing whitespace
        elseif stage == 2 then
            current.stage = 3 --Next stage after poping from stack

            pushState(state)

            state.current = {
                tokenizer = "whitespace",
                stage = 0
            }

            return "text"
        
        --Pop out of stack
        elseif stage == 3 then
            popState(state)
            return "text"
        end
    
    --Parse a string block
    elseif current.tokenizer == "string" then
        --Parse string start
        if stage == 0 then
            if not stream:eat('"') then return errorState(state) end

            current.stage = 1

            return "string"
        
        --Parse the string content and it's end
        elseif stage == 1 then
            while true do
                stream:eatChain('[^%c"\\]') --Parse everything not: control character, a back slash \, and double quote "

                if stream:eol() then --End of stream, which is end of line, so the string is multiline -> has a control character
                    errorState(state)
                    break
                elseif stream:eat('"') then --End of string
                    popState(state)
                    break
                elseif stream:eat("\\") then --Escape
                    stream:backUp(1)
                    current.stage = 2
                    break
                elseif stream:eat("%c") then --A control character, error the parser
                    stream:backUp(1)
                    errorState(state)
                    break
                end
            end

            return "string"
        --Parse escape sequence
        elseif stage == 2 then
            stream:next() --Skip (\)
            if stream:eat('["\\/bfnrt]') then --Control character escaped
                current.stage = 1
                return "escape"
            elseif stream:eat("u") then --Unicode escape
                if not stream:match("%x%x%x%x") then
                    stream:backUp(2) --Fix re-highlighting
                    return errorState(state) --Invalid hex digits
                end

                current.stage = 1
                return "escape"
            end

            return errorState(state)
        end

    --Parse a number block
    elseif current.tokenizer == "number" then
        if stage == 0 then
            stream:eat("-") --If exists
            if not stream:eat("0") and not stream:eatChain("[0123456789]") then
                stream:backUp(1)
                return errorState(state) ---No integer part
            end

            --The integer section has been verified
            current.stage = 1
            return "number"
        end

        if stage == 1 then
            if stream:eat("%.") then --fraction
                if not stream:eatChain("[0123456789]") then
                    errorState(state) --No fraction digits
                    --Highlight the verified part
                    stream:backUp(1) --I don't want the (.) highlighted as verified
                    return "number"
                end
            end

            --The fraction section has been verified
            current.stage = 2
            return "number"
        end

        if stage == 2 then
            if stream:eat("[eE]") then --exponent
                local sign = stream:eat("[%-%+]") --If exists
                if not stream:eatChain("[0123456789]") then
                    errorState(state) --No exponent digits
                    --Highlight the verified part
                    stream:backUp(sign and 2 or 1) --I don't want the (e/E) and the sign highlighted as verified
                    return "number"
                end
            end

            --The exponent section has been verified and the number has been finished
            popState(state)
            return "number"
        end

    --Parse an object block
    elseif current.tokenizer == "object" then
        if stage == 0 then --Parse starting {
            if stream:eat("{") then
                current.stage = 1 --Stage after skipping whitespace

                pushState(state)
                state.current = {
                    tokenizer = "whitespace",
                    stage = 0
                }

                return "text"
            end

            return errorState(state)
        elseif stage == 1 then --Parse string start or }
            if stream:eat("}") then --Object end
                popState(state)
                return "text"
            end

            current.stage = 4 --Parse string start
            return "text"

        elseif stage == 2 then --Parse : then value
            if stream:eat(":") then
                current.stage = 3 --Stage after parsing value

                --Parse value
                pushState(state)
                state.current = {
                    tokenizer = "value",
                    stage = 0
                }

                return "text"
            end

            return errorState(state)
        elseif stage == 3 then --Parse , or }
            if stream:eat(",") then --New index
                current.stage = 4 --Stage after parsing whitespace

                pushState(state)
                state.current = {
                    tokenizer = "whitespace",
                    stage = 0
                }

                return "text"
            elseif stream:eat("}") then
                popState(state)
                return "text"
            end

            return errorState(state)
        elseif stage == 4 then --Parse string start
            if stream:peek() == '"' then --String start
                current.stage = 2 --Stage after parsing string and whitespace

                --Parse whitespace after parsing string
                pushState(state)
                state.current = {
                    tokenizer = "whitespace",
                    stage = 0
                }

                --Parse string
                pushState(state)
                state.current = {
                    tokenizer = "string",
                    stage = 0
                }

                return "text"
            end

            return errorState(state)
        end

    --Parse an array block
    elseif current.tokenizer == "array" then
        if stage == 0 then --Parse starting [
            if stream:eat("%[") then
                current.stage = 1 --Stage after skipping whitespace

                pushState(state)

                state.current = {
                    tokenizer = "whitespace",
                    stage = 0
                }

                return "text"
            end

            return errorState(state)
        elseif stage == 1 then --Parse a value or array end
            if stream:eat("%]") then --Array end
                popState(state)
                return "text"
            end

            current.stage = 2 --Stage after reading a value

            pushState(state)

            state.current = {
                tokenizer = "value",
                stage = 1 --Skip pre-whitespace stage
            }

            return "text"
        
        elseif stage == 2 then --Parse (,) or (])
            if stream:eat("%]") then
                popState(state)
                return "text"
            elseif stream:eat(",") then
                pushState(state)

                state.current = {
                    tokenizer = "value",
                    stage = 0
                }

                return "text"
            end

            return errorState(state)
        end

    --Parse a whitespace block
    elseif current.tokenizer == "whitespace" then
        stream:eatChain("[ \n\r\t]") --The supported whitespace characters
        if not stream:eol() then popState(state) end --The stream ends at each new line

        return "text"
    end
end

return {
    startState = {
        current = {
            tokenizer = "value",
            stage = 0
        },
        stack = {
            {
                tokenizer = "error",
                stage = 0
            }
        }
    },
    token = token
}