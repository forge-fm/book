"""
Pygments lexer for Forge (https://forge-fm.org)
Based on Alloy with Forge-specific extensions.
"""

import re
from pygments.lexer import RegexLexer, bygroups, include
from pygments.token import (
    Comment, Keyword, Name, Operator, Punctuation,
    String, Number, Whitespace
)


class ForgeLexer(RegexLexer):
    name = 'Forge'
    url = 'https://forge-fm.org'
    aliases = ['forge']
    filenames = ['*.frg']
    mimetypes = ['text/x-forge']

    flags = re.MULTILINE | re.DOTALL

    iden_rex = r'[a-zA-Z_][\w\']*"*'
    string_rex = r'"(\\\\|\\[^\\]|[^"\\])*"'
    text_tuple = (r'[^\S\n]+', Whitespace)

    tokens = {
        'sig': [
            (r'(extends)\b', Keyword, '#pop'),
            (iden_rex, Name.Class),
            text_tuple,
            (r',', Punctuation),
            (r'\{', Operator, '#pop'),
        ],
        'module': [
            text_tuple,
            (iden_rex, Name.Namespace, '#pop'),
        ],
        'fun': [
            text_tuple,
            (r'\{', Operator, '#pop'),
            (r'\[', Operator, '#pop'),
            (iden_rex, Name.Function, '#pop'),
        ],
        'fact': [
            include('fun'),
            (string_rex, String, '#pop'),
        ],
        'root': [
            # Comments
            (r'--.*?$', Comment.Single),
            (r'//.*?$', Comment.Single),
            (r'/\*.*?\*/', Comment.Multiline),
            text_tuple,

            # Language declaration
            (r'(#lang)(\s+)([\w/]+)', bygroups(Keyword.Namespace, Whitespace, Name.Namespace)),

            # Module/imports
            (r'(module|open)(\s+)', bygroups(Keyword.Namespace, Whitespace), 'module'),

            # Options
            (r'(option)(\s+)(\w+)', bygroups(Keyword.Namespace, Whitespace, Name.Attribute)),

            # Declarations
            (r'(sig|enum)(\s+)', bygroups(Keyword.Declaration, Whitespace), 'sig'),
            (r'(fun|pred|assert)(\s+)', bygroups(Keyword.Declaration, Whitespace), 'fun'),
            (r'(fact)(\s+)', bygroups(Keyword.Declaration, Whitespace), 'fact'),

            # Testing (Forge-specific)
            (r'(example|inst|test)(\s+)', bygroups(Keyword.Declaration, Whitespace), 'fun'),
            (r'\b(sat|unsat|theorem|checked|sufficient|necessary)\b', Keyword),

            # Constants
            (r'\b(iden|univ|none|True|False)\b', Keyword.Constant),

            # Types
            (r'\b(int|Int|String)\b', Keyword.Type),

            # Keywords
            (r'\b(var|this|abstract|extends|set|seq|one|lone|pfunc|func|let)\b', Keyword),
            (r'\b(all|some|no|sum|disj|when|else|if|then)\b', Keyword),
            (r'\b(run|check|for|but|exactly|expect|as|steps|is|linear)\b', Keyword),

            # Temporal operators
            (r'\b(always|eventually|until|releases|after|next_state)\b', Keyword),
            (r'\b(historically|once|since|triggered|before|prev_state)\b', Keyword),

            # Logical operators
            (r'\b(and|or|implies|iff|in|not)\b', Operator.Word),

            # Symbol operators
            (r'!|#|&&|\+\+|<<|>>|>=|<=>|<=|\.\.|\.|->', Operator),
            (r'[-+/*%=<>&!^|~{}\[\]().\';]', Operator),

            # Identifiers
            (iden_rex, Name),

            # Punctuation & literals
            (r'[:,]', Punctuation),
            (r'[0-9]+', Number.Integer),
            (string_rex, String),
            (r'\n', Whitespace),
        ],
    }
