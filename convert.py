#!/usr/bin/env python

from PIL import Image
from json import load

output = load(file('output.json'))

width = output['width']
height = output['height']
data = [ tuple(datum) for datum in output['data'] ]

img = Image.new("RGB", (width, height))

img.putdata(data)
img.save('image.bmp')
