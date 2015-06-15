
module.exports = (exp_token, tokens, index, offset) ->

    type = tokens[index + offset][0]
    capture_key = exp_token.match.slice 2, exp_token.match.length - 2
    captured =
        key: capture_key
        skip_tokens: 1
        location: line: tokens[index + offset][2].first_line, col: tokens[index + offset][2].first_column

    switch type
        when "null"
            captured.value = type: "null"

        when "undefined"
            captured.value = type: "undefined"

        when "IDENTIFIER"
            captured.value = val: tokens[index + offset][1], type: "ref"

        when "STRING"
            val = tokens[index + offset][1].replace /'/g, ""
            val = val.replace /"/g, ""
            captured.value = val: val, type: "string"

        when "NUMBER"
            val = tokens[index + offset][1]
            captured.value = val: val, type: "number"

        when "REGEX"
            val = tokens[index + offset][1]
            captured.value = val: val, type: "regex"

        when "BOOL"
            val = null
            if tokens[index + offset][1] in ["true", "yes", "on"]
                val = true
            else if tokens[index + offset][1] in ["false", "no", "off"]
                val = false
            captured.value = val: val, type: "boolean"

        # Function declaration
        when "PARAM_START"
            fn_params = []
            next_index = index + offset + 1
            while tokens[next_index][0] isnt "PARAM_END"
                if tokens[next_index][0] is "IDENTIFIER"
                    # Check for default value
                    param = name: tokens[next_index][1]
                    if tokens[next_index + 1][0] is "="
                        param.default = tokens[next_index + 2][1]
                    fn_params.push param
                next_index++
            captured.value =
                type: "function"
                params: fn_params
            captured.skip_tokens = next_index

        # Array literal
        when "["
            captured.value = type: "array"

        # Object
        when "{"
            obj_keys = []
            next_index = index + offset + 1

            while tokens[next_index][0] isnt "}"
                if tokens[next_index][0] is "IDENTIFIER"
                    obj_key = name: tokens[next_index][1]
                    if tokens[next_index + 1][0] is ":"
                        if tokens[next_index + 2][0] in ["IDENTIFIER", "STRING", "NUMBER", "BOOLEAN", "REGEX"]
                            # Make sure identifier isnt a call start
                            if (next_index + 3) < tokens.length and tokens[next_index + 3][0] isnt "CALL_START"
                                obj_key.value = tokens[next_index + 2][1]
                                switch tokens[next_index + 2][0]
                                    when "IDENTIFIER" then obj_key.type = "ref"
                                    when "NUMBER" then obj_key.type = "number"
                                    when "STRING" then obj_key.type = "string"
                                    when "BOOLEAN" then obj_key.type = "boolean"
                                    when "REGEX" then obj_key.type = "regex"
                    obj_keys.push obj_key
                next_index++

            captured.value =
                type: "object"
                keys: obj_keys
            captured.skip_tokens = next_index

        else return undefined

    return captured
