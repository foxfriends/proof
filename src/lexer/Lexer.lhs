\documentclass{article}
\usepackage{../../literate}

\begin{document}

\section{Lexer}

The Lexer reads the proof code and produces the list of tokens that represents
it.

\begin{code}
module Lexer where
  import Data.Char
  import Data.List.Split
\end{code}

These tokens are represented as \ident{LexerToken}s, and are as follows

\begin{code}
  data Token  = ID String
              | LParen
              | RParen
              | LBrack
              | RBrack
              | Arrow
              | Exists
              | ForAll
              | Number Integer Integer
              | OpAdd
              | OpSub
              | OpMul
              | OpDiv
              | OpMod
              | OpLT
              | OpGT
              | OpAnd
              | OpOr
              | Negation
              | Bottom
              | Comma
              | Colon
              | Type
              | TypeOf
              | Val
              deriving (Show)
\end{code}

The string itself is chopped up by the \ident{munch} function, which uses the
simplified maximal munch algorithm to produce tokens.

\begin{code}
  munch :: String -> (Token, String)
  munch = extractTokenStr Start ""
\end{code}

As you may have noticed, the actual munching is performed by
\ident{extract\-Token\-Str}, while munch simply serves as an entry point. Before
defining that, however, we require a few helper definitions.

First are the states which the state machine used for munching can be in:

\begin{code}
  data State = Start | Identifier | Numeric | NumericPoint | Single | PossibleArrow
\end{code}

Then, we have a few helper functions which can identify classes of characters.

\ident{isIdent} checks that a character is a valid character for an identifier,
i.e. alphanumeric, or an underscore.

\ident{isSingle} checks that a character is one of the characters that makes up
a whole token on its own.

\begin{code}
  isIdent :: Char -> Bool
  isIdent c = isAlphaNum c || c == '_'

  isSingle :: Char -> Bool
  isSingle c = c `elem` "()[]<>+-,=%*/:∀∃→∧∨⊥¬"

  extractTokenStr :: State -> String -> String -> (Token, String)
  extractTokenStr state token code = case state of
    Start         -> case code of
      '.' : rest            -> extractTokenStr NumericPoint ".0" rest
      '-' : rest            -> extractTokenStr PossibleArrow "-" rest
      l : rest | isAlpha l || l == '_'
                            -> extractTokenStr Identifier [l] rest
      n : rest | isDigit n  -> extractTokenStr Numeric [n] rest
      o : rest | isSingle o -> extractTokenStr Single [o] rest
      w : rest | isSpace w  -> extractTokenStr Start [] rest
      _                     -> error $ "Lexer could not process character sequence " ++ code -- TODO: LexerError
    Identifier    -> case code of
      l : rest | isIdent l  -> extractTokenStr Identifier (l : token) rest
      _                     -> (convertToToken token, code)
    Numeric       -> case code of
      '.' : rest            -> extractTokenStr NumericPoint ('.' : token) rest
      l : rest | isDigit l  -> extractTokenStr Numeric (l : token) rest
      _                     -> (Number (read $ reverse token) 0, code)
    NumericPoint  -> case code of
      l : rest | isDigit l  -> extractTokenStr NumericPoint (l : token) rest
      _                     -> (Number (read left) (read right), code)
                                where [left, right] = map reverse $ reverse $ splitOn "." token
    PossibleArrow -> case code of
      '>' : rest            -> extractTokenStr Single ">-" rest
      _                     -> (convertToToken token, code)
    Single        -> (convertToToken token, code)
\end{code}

The strings extracted by \ident{extractTokenStr}, other than the numeric ones,
are converted to actual tokens by \ident{convertToToken}. This function expects
that the token be written backwards because that's how \ident{extractTokenStr}
makes them.

Is that a stupid design for this function? Probably, but I think it will be ok.

\begin{code}
  convertToToken :: String -> Token
  convertToToken "→" = Arrow
  convertToToken ">-" = Arrow
  convertToToken "(" = LParen
  convertToToken ")" = RParen
  convertToToken "[" = LBrack
  convertToToken "]" = RBrack
  convertToToken "<" = OpLT
  convertToToken ">" = OpGT
  convertToToken "-" = OpSub
  convertToToken "+" = OpAdd
  convertToToken "/" = OpDiv
  convertToToken "*" = OpMul
  convertToToken "%" = OpMod
  convertToToken ":" = Colon
  convertToToken "," = Comma
  convertToToken "∃" = Exists
  convertToToken "stsixe" = Exists
  convertToToken "∀" = ForAll
  convertToToken "llarof" = ForAll
  convertToToken "¬" = Negation
  convertToToken "⊥" = Bottom
  convertToToken "dna" = OpAnd
  convertToToken "∧" = OpAnd
  convertToToken "ro" = OpOr
  convertToToken "∨" = OpOr
  convertToToken "epyt" = Type
  convertToToken "foepyt" = TypeOf
  convertToToken "lav" = Val
  convertToToken t = ID $ reverse t
\end{code}

The \ident{munch} function is finally used by \ident{lexify}, which will
continually munch the text until no text remains, producing the full list of
munched tokens.

\begin{code}
  lexify :: String -> [Token]
  lexify [] = []
  lexify code = token : lexify rest
    where (token, rest) = munch code
\end{code}

\end{document}
