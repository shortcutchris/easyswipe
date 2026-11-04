#!/usr/bin/env python3
"""Generate a loopback-only fixture retaining the production archive signature."""
import json
import pathlib
import sys
import xml.etree.ElementTree as ET

stage, output, previous_build, build = sys.argv[1:]
stage, output = pathlib.Path(stage), pathlib.Path(output)
output.mkdir(parents=True, exist_ok=True)
tree = ET.parse(stage / 'appcast.xml')
sparkle = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
channel = tree.getroot().find('channel')
matches = 0
for item in list(channel.findall('item')):
    enclosure = item.find('enclosure')
    item_build = item.findtext(f'{{{sparkle}}}version') or enclosure.get(f'{{{sparkle}}}version')
    if item_build != build:
        channel.remove(item)
        continue
    assert enclosure.get(f'{{{sparkle}}}edSignature')
    enclosure.set('url', 'http://127.0.0.1:18746/candidate.zip')
    matches += 1
assert matches == 1
tree.write(output / 'appcast.xml', encoding='utf-8', xml_declaration=True)
(output / 'test-config.json').write_text(json.dumps({'previousBuild': previous_build, 'installedBuild': build}))
