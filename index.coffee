fs = require "fs"
path = require "path"
{Lexer} = require "coffee-script/lib/coffee-script/lexer"

capture_exp = require "./lib/capture_exp"

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


module.exports.parse = (expression, source = "", callback) ->
    matches = []
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
                if exp_token.token[0] is tokens[i + exp_index][0] and exp_token.token[1] is tokens[i + exp_index][1]
                    continue
                else
                    is_match = false
                    break
            else if exp_token.type is "capture"
                captured_exp = capture_exp exp_token, tokens, i, exp_index
                if captured_exp
                    captured[captured_exp.key] = captured_exp.value
                else
                    is_match = false
                    break

                if exp_tokens[exp_index + 1].type is "end"
                    console.log "break end"
                    break

            else if exp_token.type is "end"
                break
            else
                is_match = false
                break

            # console.log exp_token
        if is_match
            matches.push captured

    callback null, matches
