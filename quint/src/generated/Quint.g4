/**
 * A grammar of Quint
 *
 * Our goals are:
 *  1. Keep the grammar simple,
 *  2. Make it expressive enough to capture all of the TLA logic.
 *
 * @author: Igor Konnov, Shon Feder, Gabriela Moreira, Jure Kukovec, Thomas Pani
 *          Informal Systems, 2021-2022
 */
grammar Quint;

module : 'module' IDENTIFIER '{' (docLines unit)* '}';
docLines : DOCCOMMENT*;

// a module unit
unit :    'const' IDENTIFIER ':' type                     # const
        | 'var'   IDENTIFIER ':' type                     # var
        | 'assume' identOrHole '=' expr                   # assume
        | operDef                                         # oper
        | module                                          # moduleNested
        | instanceMod                                     # instance
        | 'type' IDENTIFIER                               # typedef
        | 'type' IDENTIFIER '=' type                      # typedef
        | 'import' path '.' identOrStar                   # importDef
        // https://github.com/informalsystems/quint/issues/378
        //| 'nondet' IDENTIFIER (':' type)? '=' expr ';'? expr {
        //  const m = "QNT007: 'nondet' is only allowed inside actions"
        //  this.notifyErrorListeners(m)
        //}                                                 # nondetError
        ;

// An operator definition.
// We embed two kinds of parameters right in this rule.
// Otherwise, the parser would start recognizing parameters everywhere.
operDef : qualifier normalCallName
            ( /* ML-like parameter lists */
                '(' (IDENTIFIER (',' IDENTIFIER)*)? ')' (':' type)?
                | ':' type
              /* C-like parameter lists */
                | '(' (IDENTIFIER ':' type (',' IDENTIFIER ':' type)*) ')' ':' type
            )?
            ('=' expr)? ';'?
        ;

qualifier : 'val'
          | 'def'
          | 'pure' 'val'
          | 'pure' 'def'
          | 'action'
          | 'run'
          | 'temporal'
          ;

// an instance may have a special parameter '*',
// which means that the missing parameters are identity, e.g., x = x, y = y
instanceMod :   'module' IDENTIFIER '=' IDENTIFIER
                '('
                  (MUL |
                  IDENTIFIER '=' expr (',' IDENTIFIER '=' expr)* (',' MUL)?)
                ')'
        ;

// Types in Type System 1.2 of Apalache, which supports discriminated unions
type :          <assoc=right> type '->' type                    # typeFun
        |       <assoc=right> type '=>' type                    # typeOper
        |       '(' (type (',' type)*)? ','? ')' '=>' type      # typeOper
        |       SET '[' type ']'                                # typeSet
        |       LIST '[' type ']'                               # typeList
        |       '(' type ',' type (',' type)* ','? ')'          # typeTuple
        |       '{' row '}'                                     # typeRec
        |       typeUnionRecOne+                                # typeUnionRec
        |       'int'                                           # typeInt
        |       'str'                                           # typeStr
        |       'bool'                                          # typeBool
        |       IDENTIFIER                                      # typeConstOrVar
        |       '(' type ')'                                    # typeParen
        ;

typeUnionRecOne : '|' '{' IDENTIFIER ':' STRING (',' row)? ','? '}'
                ;

row : | (IDENTIFIER ':' type ',')* ((IDENTIFIER ':' type) (',' | '|' (IDENTIFIER))?)?
      | '|' (IDENTIFIER)
    ;

// A Quint expression. The order matters, it defines the priority.
// Wherever possible, we keep the same order of operators as in TLA+.
expr:           // unary minus
                MINUS expr                                          # uminus
                // apply a built-in operator via the dot notation
        |       expr '.' nameAfterDot (LPAREN argList? RPAREN)?     # dotCall
        |       lambda                                              # lambdaCons
                // Call a user-defined operator or a built-in operator.
                // The operator has at least one argument (otherwise, it's a 'val').
        |       normalCallName '(' argList? ')'                     # operApp
                // list access via index
        |       expr '[' expr ']'                                   # listApp
                // power over integers
        |       <assoc=right> expr op='^' expr                      # pow
                // integer arithmetic
        |       expr op=(MUL | DIV | MOD) expr                      # multDiv
        |       expr op=(PLUS | MINUS) expr                         # plusMinus
                // standard relations
        |       expr op=(GT | LT | GE | LE | NE
                        | EQ | IN | NOTIN ) expr                    # relations
        |       IDENTIFIER '\'' ASGN expr                           # asgn
        |       expr '=' expr {
                  const m = "QNT006: unexpected '=', did you mean '=='?"
                  this.notifyErrorListeners(m)
                }                                                   # errorEq
                // Boolean operators. Note that not(e) is just a normal call
        |       expr AND expr                                       # and
        |       expr OR expr                                        # or
        |       expr IFF expr                                       # iff
        |       expr IMPLIES expr                                   # implies
        |       expr MATCH
                    ('|' STRING ':' identOrHole '=>' expr)+         # match
                // similar to indented /\ and indented \/ of TLA+
        |       'and' '{' expr (',' expr)* ','? '}'                 # andExpr
        |       'or'  '{' expr (',' expr)* ','? '}'                 # orExpr
        |       'all' '{' expr (',' expr)* ','? '}'                 # actionAll
        |       'any' '{' expr (',' expr)* ','? '}'                 # actionAny
        |       ( IDENTIFIER | INT | BOOL | STRING)                 # literalOrId
        //      a tuple constructor, the form tup(...) is just an operator call
        |       '(' expr ',' expr (',' expr)* ','? ')'              # tuple
        //      short-hand syntax for pairs, mainly designed for maps
        |       expr '->' expr                                      # pair
        |       '{' IDENTIFIER ':' expr
                        (',' IDENTIFIER ':' expr)* ','? '}'         # record
        //      a list constructor, the form list(...) is just an operator call
        |       '[' (expr (',' expr)*)? ','? ']'                    # list
        |       'if' '(' expr ')' expr 'else' expr                  # ifElse
        |       operDef expr                                        # letIn
        |       'nondet' IDENTIFIER (':' type)? '=' expr ';'? expr  # nondet
        |       '(' expr ')'                                        # paren
        |       '{' expr '}'                                        # braces
        ;

// A probing rule for REPL.
// Note that a top-level declaration has priority over an expression.
// For example, see: https://github.com/informalsystems/quint/issues/394
unitOrExpr :    unit | expr;

// This rule parses anonymous functions, e.g.:
// 1. x => e
// 2. (x) => e
// 3. (x, y, z) => e
lambda:         identOrHole '=>' expr
        |       '(' identOrHole (',' identOrHole)* ')' '=>' expr
        ;

// an identifier or a hole '_'
identOrHole :   '_' | IDENTIFIER
        ;

// an identifier or a star '*'
identOrStar :   '*' | IDENTIFIER
        ;

// a path used in imports
path    : IDENTIFIER ('.' IDENTIFIER)*
        ;

argList :      expr (',' expr)*
        ;

// operators in the normal call may use a few reserved names,
// which are not recognized as identifiers.
normalCallName :   IDENTIFIER
        |       op=(AND | OR | IFF | IMPLIES | SET | LIST | MAP)
        ;

// A few infix operators may be called via lhs.oper(rhs),
// without causing any ambiguity.
nameAfterDot :  IDENTIFIER
        |       op=(AND | OR | IFF | IMPLIES)
        ;

// special operators
operator: (AND | OR | IFF | IMPLIES |
           GT  | LT  | GE  | LE | NE | EQ |
           MUL | DIV | MOD | PLUS | MINUS | '^')
        ;

// literals
literal: (STRING | BOOL | INT)
        ;

// TOKENS

// literals
// Strings cannot be escaped, as they are pseudo-identifiers.
STRING          : '"' .*? '"' ;
BOOL            : ('false' | 'true') ;
INT             : [0-9]+ ;

// a few keywords
AND             :   'and' ;
OR              :   'or'  ;
IFF             :   'iff' ;
IMPLIES         :   'implies' ;
SET             :   'Set' ;
LIST            :   'List' ;
MAP             :   'Map' ;
MATCH           :   'match' ;
PLUS            :   '+' ;
MINUS           :   '-' ;
MUL             :   '*' ;
DIV             :   '/' ;
MOD             :   '%' ;
GT              :   '>' ;
LT              :   '<' ;
GE              :   '>=' ;
LE              :   '<=' ;
NE              :   '!=' ;
EQ              :   '==' ;
ASGN            :   '=' ;
LPAREN          :   '(' ;
RPAREN          :   ')' ;

// other TLA+ identifiers
IDENTIFIER             : SIMPLE_IDENTIFIER | SIMPLE_IDENTIFIER '::' IDENTIFIER ;
SIMPLE_IDENTIFIER      : ([a-zA-Z][a-zA-Z0-9_]*|[_][a-zA-Z0-9_]+) ;

DOCCOMMENT : '///' .*? '\n';

// comments and whitespaces
LINE_COMMENT    :   '//' .*? '\n'   -> skip ;
COMMENT         :   '/*' .*? '*/'   -> skip ;
WS              :   [ \t\r\n]+      -> skip ; // skip spaces, tabs, newlines
