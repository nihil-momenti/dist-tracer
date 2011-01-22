#!/usr/bin/env python

from PIL import Image
import json
import sys

output = json.load(sys.stdin)

width = output['width']
height = output['height']
name = 'images/' + str(output['id']) + '/image.bmp'
data = [ tuple(datum) for datum in output['data'] ]

img = Image.new("RGB", (width, height))

img.putdata(data)

img.save(name)

print name
