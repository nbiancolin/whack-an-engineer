'''
imgToV
(c) 2023 Nicholas Biancolin - All Rights Reserved


Takes in an image file, spits out a text file that enables you to draw your provided picture 
(by drawing a box with the same dimensions as your image)
'''

from PIL import Image
import math
import argparse

''' 
** GLOBAL VARIABLES **
Set these to be the counter values used in your box drawing code. 
(xProgress, xCounter, count[1:0] / count[3:2], etc)
'''

XCOUNT = 'xProgress'
YCOUNT = 'yProgress'


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


def generate_color_condition(x, y, col, flag):
    if (not flag): condition = f"else if({XCOUNT} == {x} && {YCOUNT} == {y})"
    else: condition = f"if({XCOUNT} == {x} && {YCOUNT} == {y})"
    condition += " color <= 3'b"
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
    #print(args.filename)

    xReg = math.log2(size[0])
    yReg = math.log2(size[1])
    

    #beginning file stuff
    file = args.filename + ".txt"
    f = open(file, "w")
    #f = open("output.txt", "w")
    f.write("# imgToV Converter\n")
    #f.write("# this code assumes clock is labelled as \' clk \'\n\n")

    f.write("# your counter registers should be of the following size:\n")
    f.write("# reg xProgress[")
    f.write(str(math.ceil(xReg)-1))
    f.write(":0];\n")
    f.write("# reg yProgress[")
    f.write(str(math.ceil(yReg)-1))
    f.write(":0];\n\n")

    f.write("you should be sure to set your x and y limits to ")
    f.write(str(size[0]))
    f.write(" and ")
    f.write(str(size[1]))
    f.write(" respectively\n")
    f.write("Use this code with your lab 7 part 2 module, just be sure to change the limit from being a 4 x 4 square to the above limits\n")

    f.write("comment out any lines of code that set colour, and place this after your counters are updated\n\n")

    temp = "orange juice"
    flag = True
    for y in range(size[1]):
        for x in range(size[0]):
            #print(get_colour(i,j))

            col = old_get_colour(x,y)
            
            #method of condensing code, if colour remains the same, no colour change needed
            if(temp == col): continue
            res = generate_color_condition(x,y, col, flag)
            flag = False
            f.write("\t")
            f.write(res)
            f.write("\n")
            temp = col
    
    print("Output is stored in " + args.filename + ".txt")
    print("(in same folder as this script!)")
    print(" ** IMPORTANT **")
    print("ensure to set the \"XCOUNT\" and \"YCOUNT\" global variables at the top of the python file to match your iteration variables" )