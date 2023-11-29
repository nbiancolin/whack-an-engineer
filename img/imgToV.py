#Code that takes in a picture of a thing, and writes out instructions for it to be printed with a verilog module.

'''
basically, the way this works,
module can only print one pixel at a time,
so, using x and y counter (assume they are being updated every clock cycle accordingly)
for each pixel in the image, write verilog code that sets the correct colour for the given pixel
'''

from PIL import Image
import math
import argparse

XCOUNT = 'oX'
YCOUNT = 'oY'




def get_colour(x,y): #also deprecated
    col = pix(x,y) # Convert the tuple to a list
    for i in range(3):
        if col[i] != 0:
            col[i] = 1
    return col[:-1]

def get_matrix(): #rdeprecated
    res = []
    for i in range(size[0]):
        temp = []
        for j in range(size[1]):
            temp.append(get_colour(i,j))
        res.append(temp)
    return res



def old_get_colour(x, y):
    col = list(pix[x, y])  # Convert the tuple to a list
    res = "3'b"
    for i in range(3):
        if col[i] > 31:
            col[i] = 1
        else: col[i] = 0
        res += str(col[i])
    return res




def openImage(img):
    global im
    global pix
    global size
    im = Image.open(img)
    pix = im.load()
    size = im.size
    #print(pix[5,5])


def generate_color_condition(x, y, col):
    condition = f"if({XCOUNT} == {x} and {YCOUNT} == {y})"
    condition += " color <= "
    condition += col
    condition += ";"

    return condition



if __name__ == "__main__":
    print("imgToVerilog\n") 
    parser = argparse.ArgumentParser(
                    prog='imgToV',
                    description='Converts image into verilog instructions for VGA adapter',
                    epilog='run in commandline, where first argument is the filename / filepath')
    # Required positional argument
    parser.add_argument('filename')
    args = parser.parse_args()    

    openImage(args.filename)


    xReg = math.log2(size[0])
    yReg = math.log2(size[1])
    

    #beginning file stuff
    f = open("./output/{args.filename}.txt", "w")
    f.write("# imgToV Converter\n")
    #f.write("# this code assumes clock is labelled as \' clk \'\n\n")

    f.write("# your counter registers should be of the following size:\n")
    f.write("# reg xCount[ ")
    f.write(str(math.ceil(xReg)))
    f.write(": 0];\n")
    f.write("# reg yCount[ ")
    f.write(str(math.ceil(yReg)))
    f.write(": 0];\n\n")

    f.write("you should be sure to set your x and y limits to {size[0]} and {size[1]} respectively\n")

    f.write("comment out any lines of code that set colour, and place this after your counters are updated\n\n")

    temp = "orange juice"
    for y in range(size[1]):
        for x in range(size[0]):
            #print(get_colour(i,j))

            col = old_get_colour(x,y)
            
            #method of condensing code, if colour remains the same, no colour change needed
            if(temp == col): continue
            res = generate_color_condition(x,y, col)
            f.write("\t")
            f.write(res)
            f.write("\n")
            temp = col
    
    print("Output is stored in ./output/{args.filename}.txt")
    print("(in same folder as this script!)")
    print(" ** IMPORTANT **")
    print("ensure to set the \"XCOUNT\" and \"YCOUNT\" global variables at the top of the python file to match your iteration variables" )