'''/*
* Author: Stefan Stancu
* Created: 21/11/2017
*/'''

import sys

from PIL import Image

def main(image_name):
    image = Image.open(image_name, 'r')
    pixels = list(image.getdata())
	
    mif_name = image_name.split('.')[0] + '.mif'

    mif_file = open(mif_name, 'w+')

    mif_file.write('DEPTH={};\nWIDTH={};\nADDRESS_RADIX=DEC;\nDATA_RADIX=BIN;\nCONTENT\nBEGIN\n\n'.format(len(pixels), 3))
    address = 0
    for i in range(image.size[1]):
        mif_file.write(str(i * image.size[0]) + ": ")
        for j in range(image.size[0]):
            mif_file.write(' ' + three_bit_conversion(pixels[address]))
            address+=1
        mif_file.write(';\n')

    mif_file.write('END;\n')

    mif_file.close()

    image.close()


def three_bit_conversion(rgb):
    bits = []
    for i in range(len(rgb)):
        if rgb[i] > 125:
            bits.append(1)
        else:
            bits.append(0)

    return "{}{}{}".format(bits[0], bits[1], bits[2])


if __name__ == '__main__':
    for arg in sys.argv[1:]:
        main(arg)