import Image, os

files = sorted(fname for fname in os.listdir(".") if fname.startswith('32'))

for f in files:
    print f
    im = Image.open(f)
    im = im.crop((320, 320, 1670, 760))
    out = Image.new("RGB", im.size, "black")
    out.paste(im, im)
    out.thumbnail((320, 320), Image.BILINEAR)
    out.save("out-%s" % f)
print files
