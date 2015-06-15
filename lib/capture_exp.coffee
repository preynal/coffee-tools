
module.exports = (exp_token, tokens, index, offset) ->
    type = tokens[index + offset][0]
    capture_key = exp_token.match.slice 2, exp_token.match.length - 2
    captured =
        key: capture_key
        location: line: tokens[index + offset][2].first_line, col: tokens[index + offset][2].first_column
    switch type
        when "IDENTIFIER"
            return key: capture_key, value: {val: tokens[index + offset][1], type: "ref"}
        when "STRING"
            val = tokens[index + offset][1].replace /'/g, ""
            val = val.replace /"/g, ""
            return key: capture_key, value: {val: val, type: "string"}
        when "NUMBER"
            val = tokens[index + offset][1]
            return key: capture_key, value: {val: val, type: "number"}
        when "REGEX"
            val = tokens[index + offset][1]
            return key: capture_key, value: {val:val, type: "regex"}
        when "BOOL"
            val = null
            if tokens[index + offset][1] in ["true", "yes", "on"]
                val = true
            else if tokens[index + offset][1] in ["false", "no", "off"]
                val = false
            return key: capture_key, value: {val: val, type: "boolean"}
        else
            console.log "UNKNOWN TYPE", tokens[index + offset]
            return undefined
    return captured
