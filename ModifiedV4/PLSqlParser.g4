grammar PLSqlParser;

// Lexer Rules
WS: [ \t\r\n]+ -> skip;
PROCEDURE: [Pp][Rr][Oo][Cc][Ee][Dd][Uu][Rr][Ee];
FUNCTION: [Ff][Uu][Nn][Cc][Tt][Ii][Oo][Nn];
IS: [Ii][Ss];
AS: [Aa][Ss];
BEGIN: [Bb][Ee][Gg][Ii][Nn];
END: [Ee][Nn][Dd];
AUTHID: [Aa][Uu][Tt][Hh][Ii][Dd];
CURRENT_USER: [Cc][Uu][Rr][Rr][Ee][Nn][Tt]'_'[Uu][Ss][Ee][Rr];

IDENTIFIER: [A-Za-z_$][A-Za-z0-9_$]*;
STRING: ''' (~''')* ''';
NUMBER: [0-9]+;

// Catch-all for any other text
ANY_TEXT: .+?;

// Parser Rules
packageBody
    : (procedureOrFunction)+ EOF
    ;

procedureOrFunction
    : (PROCEDURE | FUNCTION) 
      IDENTIFIER 
      parameterList?
      authidClause?
      (IS | AS)
      body
    ;

parameterList
    : '(' (IDENTIFIER (',' IDENTIFIER)*)? ')'
    ;

authidClause
    : AUTHID CURRENT_USER
    ;

body
    : bodyContent+ END (IDENTIFIER)?
    ;

bodyContent
    : BEGIN
    | END
    | ANY_TEXT
    ;
