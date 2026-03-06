#!/usr/bin/env python3
"""Convert mdbook syntax to MkDocs Material format."""

import re
import sys


def convert_code_blocks(content: str) -> str:
    """Convert mdbook code block syntax to standard markdown.

    - Converts ```forge,runnable and ```forge,editable to ```forge
    - Removes hidden lines (lines starting with ~) from code blocks
    """

    def process_code_block(match):
        fence = match.group(1)  # ``` or ~~~
        lang = match.group(2)   # language specifier
        code = match.group(3)   # code content

        # Clean up language specifier (remove ,runnable, ,editable, =, etc.)
        if lang:
            lang = re.sub(r'[,=].*', '', lang)  # Remove ,runnable, ,editable, = (line numbers), etc.

        # Remove hidden lines (lines starting with ~)
        lines = code.split('\n')
        visible_lines = []
        for line in lines:
            if not line.startswith('~'):
                visible_lines.append(line)
        code = '\n'.join(visible_lines)

        if lang:
            return f'{fence}{lang}\n{code}{fence}'
        else:
            return f'{fence}\n{code}{fence}'

    # Match code blocks: ```lang or ~~~ followed by content and closing fence
    # Capture: (fence)(optional language with possible =, etc.)(content)(closing fence)
    # Language can include: forge,runnable or java= or python etc.
    pattern = r'(```|~~~)([\w,=]+)?\n(.*?)\1'
    return re.sub(pattern, process_code_block, content, flags=re.DOTALL)


def convert_details_blocks(content: str) -> str:
    """Convert <details>/<summary> HTML to MkDocs Material collapsible admonitions.

    <details>
    <summary>Title</summary>
    Content
    </details>

    becomes:

    ??? note "Title"
        Content
    """

    def replacer(match):
        title = match.group(1).strip()
        inner_content = match.group(2)

        # Indent content by 4 spaces, but be careful with code blocks
        indented_lines = []
        in_code_block = False
        for line in inner_content.strip().split('\n'):
            # Check if we're entering or leaving a code block
            stripped = line.strip()
            if stripped.startswith('```') or stripped.startswith('~~~'):
                if in_code_block:
                    # Closing fence - indent it
                    indented_lines.append('    ' + stripped)
                    in_code_block = False
                else:
                    # Opening fence - indent it
                    indented_lines.append('    ' + stripped)
                    in_code_block = True
            elif in_code_block:
                # Inside code block - preserve original content, just add base indent
                indented_lines.append('    ' + line)
            elif line.strip():
                # Regular content - indent
                indented_lines.append('    ' + line)
            else:
                # Empty line
                indented_lines.append('')
        indented_content = '\n'.join(indented_lines)

        return f'??? note "{title}"\n{indented_content}\n'

    # Match <details><summary>Title</summary>Content</details>
    # Allow for whitespace/newlines between tags
    pattern = r'<details>\s*<summary>([^<]*)</summary>\s*(.*?)\s*</details>'
    return re.sub(pattern, replacer, content, flags=re.DOTALL | re.IGNORECASE)


def convert_admonitions(content: str) -> str:
    """Convert ~~~admonish and ```admonish blocks to !!! blocks."""

    def replacer(match):
        fence = match.group(1)  # ~~~ or ```
        full_header = match.group(2).strip()
        inner_content = match.group(3)

        # Parse the header to extract type and title
        admon_type = "note"  # default
        title = ""

        # Check for type with title/name attribute: TYPE title="..." or TYPE name="..."
        type_with_attr = re.match(r'(\w+)\s+(?:title|name)="([^"]*)"', full_header)
        if type_with_attr:
            admon_type = type_with_attr.group(1)
            title = type_with_attr.group(2)
        else:
            # Check for shorthand: TYPE="TITLE"
            shorthand = re.match(r'(\w+)="([^"]*)"', full_header)
            if shorthand:
                admon_type = shorthand.group(1)
                title = shorthand.group(2)
            else:
                # Check for just title attribute (no type): title="..."
                just_title = re.match(r'title="([^"]*)"', full_header)
                if just_title:
                    title = just_title.group(1)
                else:
                    # Check for just type (no title): TYPE
                    just_type = re.match(r'(\w+)$', full_header)
                    if just_type:
                        admon_type = just_type.group(1)

        # Indent content by 4 spaces
        indented_lines = []
        for line in inner_content.rstrip().split('\n'):
            if line.strip():
                indented_lines.append('    ' + line)
            else:
                indented_lines.append('')
        indented_content = '\n'.join(indented_lines)

        if title:
            return f'!!! {admon_type} "{title}"\n{indented_content}\n'
        else:
            return f'!!! {admon_type}\n{indented_content}\n'

    # Match both ~~~admonish and ```admonish blocks
    # Pattern: (~~~|```)admonish HEADER\n CONTENT \n(~~~|```)
    pattern = r'(~~~|```)admonish\s+([^\n]+)\n(.*?)\1'
    return re.sub(pattern, replacer, content, flags=re.DOTALL)

def convert_file(input_path: str) -> str:
    """Read a file and apply all mdbook-to-mkdocs conversions."""
    with open(input_path, 'r') as f:
        content = f.read()
    # Order matters:
    # 1. Convert admonitions first (they use ~~~)
    # 2. Convert <details> blocks to collapsible admonitions
    # 3. Handle regular code blocks last
    content = convert_admonitions(content)
    content = convert_details_blocks(content)
    content = convert_code_blocks(content)
    return content

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: convert.py <input_file>")
        sys.exit(1)

    print(convert_file(sys.argv[1]))
