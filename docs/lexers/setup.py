from setuptools import setup

setup(
    name='forge-pygments-lexer',
    version='1.0.0',
    py_modules=['forge_lexer'],
    entry_points={
        'pygments.lexers': [
            'forge = forge_lexer:ForgeLexer',
        ],
    },
    install_requires=['pygments'],
)
