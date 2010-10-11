{ open Parser }

rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf }
| "/*" {comment lexbuf}
| '"' [^ '"']* '"' as s { STRINGLIT( String.sub s 1 (String.length s - 2)) }
| '+' { PLUS }
| '-' { MINUS }
| '*' { TIMES }
| '/' { DIVIDE }
| '<' { LESSTHAN }
| '>' { GREATERTHAN }
| "==" { EQUAL }
| "!=" { NEQUAL }
| "and" {LOGICAND}
| "or" {LOGICOR}
| ';' {SEMICOLON}
| '=' {ASSIGN}
| "if" {IF}
| "then" {THEN}
| "else" {ELSE}
| '{' {LBRACKET}
| '}' {RBRACKET}
| '(' {LPAREN}
| ')' {RPAREN}
| ',' {COMMA}
| ['0'-'9']+ as lit { LITERAL(int_of_string lit) }
| ['A'-'Z' 'a'-'z'] ['A'-'Z' 'a'-'z' '0'-'9' '_']* as var { VARIABLE (var) }
| eof { EOF }

and comment = parse
| "*/" {token lexbuf }
| _ {comment lexbuf}

