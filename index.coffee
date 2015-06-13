fs = require "fs"
path = require "path"
{Lexer} = require "coffee-script/lib/coffee-script/lexer"

# Transforms input string into coffee tokens
tokenize_expression = (expression) ->
    # Tokenize expression
    expression_vars = expression.match /{(.*?)}/g
    expression_targets = []
    expr_string = expression
    if expression_vars and expression_vars.length > 0
        for match in expression_vars
            do (match) ->
                target = match.replace "{", ""
                target = target.replace "}", ""
                target = "__#{target}__"
                expression_targets.push target
                expr_string = expr_string.replace match, target

    opts = bare: true, header: false, sourceMap: false
    tokens = (new Lexer()).tokenize expr_string, opts

    result = []
    for index in [0...tokens.length]
        token = tokens[index]
        has_match = false
        for target in expression_targets when has_match is false
            if token[1].indexOf(target) > -1
                result.push type: "capture", match: target
                has_match = true

        if index is tokens.length - 1 or token[0] is "CALL_END"
            result.push type: "end"
            break

        unless has_match then result.push type: "match", token: token

    return result


find = (expression, source = "") ->
    result = []
    # Tokenize source
    opts = bare: true, header: false, sourceMap: false
    tokens = (new Lexer()).tokenize source, opts

    exp_tokens = tokenize_expression expression
    # console.log JSON.stringify exp_tokens, null, 4

    for i in [0...tokens.length]
        token = tokens[i]
        is_match = true
        captured = {}
        for exp_index in [0...exp_tokens.length] when (i + exp_index) < tokens.length and is_match
            exp_token = exp_tokens[exp_index]
            # console.log "---"
            # console.log "TOKEN", token
            # console.log "EXP_TOKEN", token
            if exp_token.type is "match"
                if exp_token.token[0] is tokens[i + exp_index][0]
                    if exp_token.token[1] is tokens[i + exp_index][1]
                        continue
                    else
                        # console.log "IDENTIFIER NOT matching"
                        is_match = false
                        break
                else
                    # console.log "MATCH NOT matching"
                    # console.log "TOKEN", exp_token.token
                    # console.log "TARGET TOKEN", tokens[i + exp_index]
                    is_match = false
                    break
            else if exp_token.type is "capture"
                if tokens[i + exp_index][0] is "IDENTIFIER"
                    # console.log "CAPTURED1:", exp_token.match, tokens[i + exp_index][1]
                    capture_key = exp_token.match.replace "__", ""
                    capture_key = capture_key.replace "__", ""
                    captured[capture_key] = tokens[i + exp_index][1]
                else if tokens[i + exp_index][0] is "STRING"
                    capture_key = exp_token.match.replace "__", ""
                    capture_key = capture_key.replace "__", ""
                    capture_value = tokens[i + exp_index][1].replace /'/g, ""
                    capture_value = capture_value.replace /"/g, ""
                    # console.log "CAPTURED2:", capture_key, capture_value
                    captured[capture_key] = capture_value
                else
                    # console.log "WRONG CAPTURE"
                    # console.log  tokens[i + exp_index + 6]
                    is_match = false
                    break

                # console.log "-----\n\n"
                # console.log exp_tokens[exp_index]
                # console.log exp_tokens[exp_index + 1]
                if exp_tokens[exp_index + 1].type is "end"
                    # console.log "break end"
                    break

            else if exp_token.type is "end"
                # console.log "END"
                break
            else
                is_match = false
                break

            # console.log exp_token
        if is_match
            result.push captured
        # console.log token, i
    return result

# find "'b' \"a\""
source = fs.readFileSync "test.coffee", "utf8"
console.log find "{route} = require \"{file}\"", source
