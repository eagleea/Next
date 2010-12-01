open Ast
open Expression
open Declaration
open Action
open Selection
open Start
open Statement

module type COMPILE = 
   sig
     exception CompileError of string
     val javacode : globaldec list -> string list * string list
     val stmt_to_java : string list * string list -> stmt -> string list * string list
	 val global_dec_to_java : string list * string list -> globaldec -> string list * string list
   end

module Compile : COMPILE = struct

exception CompileError of string

(* TODO: FIX THIS *)
let global_dec_to_java (playcode, startfns) global_dec = match global_dec with
	IntStrdec (pridec) -> ([], []) 
  | Charadec (name, membervar1, membervar2) -> ([], [])
  | Itemdec (name, membervar) -> ([], [])
  | Locdec (name, membervar1, membervar2, membervar3) -> ([], [])
  | Startend (name, condition_expr, stmt) -> ([], [])

let rec startend_stmt_check (expression:string) (statement:string list) = match statement with
	[]->[]
	
	|hd::tl -> if (String.contains hd ';') then [hd] @ ["if (" ^expression ^")"; "endGame();"] @ 
		(startend_stmt_check expression tl) else [hd] @ (startend_stmt_check expression tl) 

let rec actiondeclist_to_java list = match list with
   [] -> []
   | hd::tail -> match hd with
         Unitaction(action, actionname, key) -> ["keysToActionName.put(\"" ^ key ^ "\", \"" ^ action ^ "\"" ^ ");";
            "actionNameToOutput.put(\"" ^ action ^ "\", \"" ^ actionname ^ "\");";
            "System.out.println(\"Type " ^ key ^ " for " ^ actionname ^ "\");"] @ actiondeclist_to_java tail

let rec prob_sum list = match list with
   [] -> 0
   | hd::tail -> match hd with Unitprob(i, stmt) -> i + (prob_sum tail)

let rec stmt_to_java (playcode, startfns) stmt = match stmt with
    Ifelse (expr, stmt1, stmt2) -> let (expr_precode, expr_exp) = Expression.expr_to_java_boolean expr in 
        let (stmt1_playcode, stmt1_startfns) = stmt_to_java ([], []) stmt1 in 
        let (stmt2_playcode, stmt2_startfns) = stmt_to_java ([], []) stmt2 in
        (playcode @ expr_precode @ ["if(" ^ expr_exp ^ ") {"] @ stmt1_playcode @ ["} else {"] @ stmt2_playcode @ ["}"], startfns @ stmt1_startfns @ stmt2_startfns)

    | Chwhen (actiondeclist, whenexprlist) -> let mapDecl = ["Map<String,String> keysToActionName = new HashMap<String, String>();"; "Map<String, String> actionNameToOutput = new HashMap<String, String>();"] in
   let actiondecs = ["System.out.println(\"CHOOSE AN ACTION:\");"] @ actiondeclist_to_java actiondeclist in
   let getinput = ["Scanner in = new Scanner(System.in);";
                   "String input = in.nextLine();";
                    "while(!keysToActionName.containsKey(input)) {";
                    "System.out.println(\"Invalid input, try again\");";
                    "input = in.nextLine();";
                    "}";
                    "System.out.println(\"You typed \" + input);";
                   "String action = keysToActionName.get(input);" ] in
   let whenexprs_playcode, whenexprs_startfns = whenexprs_to_java whenexprlist in
(playcode @ mapDecl @ actiondecs @ getinput @ whenexprs_playcode, startfns @ whenexprs_startfns)

    | Prob (probexprlist) -> let sum = prob_sum probexprlist in
    if sum != 100 then raise (CompileError "Probabilities did not sum to 100")
    else let randomcode = ["int num = r.nextInt(100);"] in
    let (probexprs_code, probexprs_startfns) = probexprs_to_java 0 probexprlist in
(playcode @ randomcode @ probexprs_code, startfns @ probexprs_startfns)

    | Kill (str) -> (playcode @ (Action.kill_to_java str), startfns)
    | Grab (str1, str2) -> (playcode @ (Action.grab_to_java str1 str2), startfns)
    | Drop (str1, str2) -> (playcode @ (Action.drop_to_java str1 str2), startfns)
    | Show (str1, str2) -> (playcode @ (Action.show_to_java str1 str2), startfns)
    | Hide (str1, str2) -> (playcode @ (Action.hide_to_java str1 str2), startfns)
    (*| Charadec (str, attrlist, itemlist) -> (playcode @ (Declaration.charadec_to_java str attrlist itemlist), startfns)
    | Itemdec (str, list) -> (playcode @ (Declaration.itemdec_to_java str list), startfns)
    | Locdec (str, attrlist, itemlist, charlist) -> (playcode @ (Declaration.locdec_to_java str attrlist itemlist charlist), startfns)
    | Startend (str, expr, stmt) -> playcode @ ["//Location function call"; str ^ "();"], startfns @ ["//start funtion"; "public void " ^ str ^ "() {"] @ 
	(fst (Expression.expr_to_java_boolean expr)) @ ["while (" ^ (snd (Expression.expr_to_java_boolean expr)) ^ "){"  ] 
	@ (startend_stmt_check (snd (Expression.expr_to_java_boolean expr)) (fst (stmt_to_java ([], []) stmt)) ) 
	@ (fst (Expression.expr_to_java_boolean expr))@ ["} }"] *)
    | Atomstmt (expr) -> (playcode @ (Statement.atomstmt_to_java expr), startfns)
    | Cmpdstmt (codeblock) ->
         List.fold_left stmt_to_java (playcode, startfns) codeblock
    | Nostmt (i) -> (playcode @ (Statement.nostmt_to_java i), startfns)
    (*| IntStrdec (pridec) -> (playcode @ (Declaration.intstrdec_to_java pridec), startfns)*)
    | Print (str) -> (playcode @ (Statement.print_to_java str), startfns)


and whenexprs_to_java list = match list with
   [] -> ([], [])
   | hd :: tail -> let (hd_playcode, hd_startfns) = whenexpr_to_java hd in
         let (tail_playcode, tail_startfns) = whenexprs_to_java tail in
      (hd_playcode @ tail_playcode, hd_startfns @ tail_startfns)

and whenexpr_to_java whenexpr = match whenexpr with Unitwhen(action, stmt, loc) -> 
   let (when_playcode, when_startfns) = stmt_to_java ([], []) stmt in 
   let nextcode = ["//" ^ loc ^ "();"] in
    (["if(action.equals(\"" ^ action ^ "\")) {"]
        @ when_playcode @ nextcode @ ["}"], when_startfns)

and probexprs_to_java start_num list = match list with
   [] -> ([], [])
   | hd::tail -> let (hd_playcode, hd_startfns, curr_num) = probexpr_to_java hd start_num in
        let (tail_playcode, tail_startfns) = probexprs_to_java curr_num tail in
       (hd_playcode @ tail_playcode, hd_startfns @ tail_startfns)

and probexpr_to_java probexpr start_num = match probexpr with Unitprob(i, stmt) -> 
    let (prob_playcode, prob_startfns) = stmt_to_java ([], []) stmt in
    (["if(num >= " ^ string_of_int start_num ^ " && num < " ^ string_of_int (start_num + i) ^ ") {"] @ prob_playcode @ ["}"], prob_startfns, start_num + i)

let javacode program = List.fold_left global_dec_to_java ([], []) program

end