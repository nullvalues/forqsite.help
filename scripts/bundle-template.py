#!/usr/bin/env python3
"""Extract and re-inject the editable template inside a forqsite.help bundle.

index.html and gap-handoff.html are self-extracting bundles. The page a reader
sees is built at runtime from a JSON-encoded HTML template carried in a
    <script type="__bundler/template"> … </script>
element, alongside compressed resource blobs. The rendered markup is not in the
file as markup, so neither a text editor nor a search-and-replace over the bundle
can safely change the page.

Two details make hand-editing unsafe, and both are why this script exists:

  1. The template is JSON-encoded, so every quote, newline and backslash inside
     it is escaped. Editing the escaped form by eye invites a broken string that
     fails at load with no useful error.
  2. The encoder escapes every forward slash as \\u002F. That is not cosmetic:
     the template contains its own "</script>" sequences, and unescaped they
     would terminate the script element carrying them, truncating the page.

Usage:
    bundle-template.py extract <bundle.html> <out.template.html>
    bundle-template.py inject  <bundle.html> <in.template.html>
    bundle-template.py verify  <bundle.html>

`verify` re-encodes the template it finds and asserts the result is byte-identical
to what is already in the file. Run it before an edit to confirm the encoder still
matches the bundler's, and after an inject to confirm the file is well-formed.
"""

import json
import re
import sys

TEMPLATE_RE = re.compile(r'(<script type="__bundler/template">)(.*?)(</script>)', re.S)


def encode(template: str) -> str:
    """Encode exactly as the bundler does: JSON, then slash-escaped."""
    return json.dumps(template, ensure_ascii=False).replace('/', '\\u002F')


def _find(source: str, path: str):
    match = TEMPLATE_RE.search(source)
    if not match:
        sys.exit(f'error: no <script type="__bundler/template"> element in {path}')
    return match


def cmd_extract(bundle: str, out: str) -> None:
    source = open(bundle, encoding='utf-8').read()
    template = json.loads(_find(source, bundle).group(2))
    open(out, 'w', encoding='utf-8').write(template)
    print(f'extracted {len(template):,} chars -> {out}')


def cmd_inject(bundle: str, template_path: str) -> None:
    source = open(bundle, encoding='utf-8').read()
    match = _find(source, bundle)
    template = open(template_path, encoding='utf-8').read()
    rebuilt = source[:match.start(2)] + encode(template) + source[match.end(2):]

    # Read back what we are about to write, rather than trusting the write.
    check = _find(rebuilt, bundle)
    if json.loads(check.group(2)) != template:
        sys.exit('error: re-parsed template does not match the input; refusing to write')

    open(bundle, 'w', encoding='utf-8').write(rebuilt)
    delta = len(rebuilt) - len(source)
    print(f'injected {len(template):,} chars into {bundle} ({delta:+,} bytes)')


def cmd_verify(bundle: str) -> None:
    source = open(bundle, encoding='utf-8').read()
    match = _find(source, bundle)
    template = json.loads(match.group(2))
    if encode(template) == match.group(2):
        print(f'{bundle}: OK — round-trip is byte-identical ({len(template):,} chars)')
        return
    # A mismatch means this script's encoder has drifted from the bundler's.
    # Say so plainly: injecting under that condition would rewrite the whole
    # template and bury the real edit in the diff.
    sys.exit(
        f'{bundle}: FAIL — re-encoding does not reproduce the file byte for byte.\n'
        '  This script\'s encoder no longer matches the bundler\'s. Do not inject:\n'
        '  every byte of the template would be rewritten and the real edit lost in the diff.'
    )


def main() -> None:
    args = sys.argv[1:]
    if not args or args[0] not in {'extract', 'inject', 'verify'}:
        sys.exit(__doc__)
    command, rest = args[0], args[1:]
    expected = 1 if command == 'verify' else 2
    if len(rest) != expected:
        sys.exit(__doc__)
    {'extract': cmd_extract, 'inject': cmd_inject, 'verify': cmd_verify}[command](*rest)


if __name__ == '__main__':
    main()
