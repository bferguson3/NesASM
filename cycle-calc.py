# NES cycle calculator
# Python3 / (c)2018 Ben Ferguson
# Compatible with NESASM 3.1
###############################
import math 
#file_read = bytearray()
file_read = []
sym_read = []

print("\n65xx (NES/C64) Assembly Cycle Calculator")
print(" -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
#print("        (c) 2018 bferguson3\n")
print("Instructions: Type the filename of the file you")
print("want to analyze, then input the beginning and ")
print("ending line numbers. I will output the exact number")
print("of cycles it will take to run your code!\n")
# To add:
# Select system type, then give warnings about sizze of code.

# take file name input
fileToRead = input("Input filename to examine (omit extension .asm): ")

# if it has no extension, append .asm
if '.' not in fileToRead:
    fileToRead = fileToRead + ".asm"
    symToRead = fileToRead[:-4] + ".fns"
# read all data per-line as strings
#with open(fileToRead, "rb") as f:
#    file_read = f.read()
with open(fileToRead, 'r') as f:
    file_read = f.readlines()
f.close()
with open(symToRead, 'r') as f:
    sym_read = f.readlines()
f.close()

# ask which lines to parse
#startLine = input("Enter hex address at which to begin parsing: $")
#endLine = input("Enter hex address to stop calculation: $")
startLine = input("Enter line number at which to begin parsing: ")
endLine = input("Enter line number to stop calculation: ")

try: 
    #startLine = int(startLine, 16)
    #endLine = int(endLine, 16)
    startLine = int(startLine)
    endLine = int(endLine)
except Exception as e:
    print(e)

# actually parse
print ("Parsing from " + str(startLine) + " to " + str(endLine) + "...")

#j = startLine
#while j < endLine:
#    print(str(file_read[startLine]))
#    j += 1
symbols= {}
m = 1
while m < len(sym_read):
    #print(sym_read[m][:-1])
    sym_read[m] = sym_read[m].split('=',1)
    string_a = sym_read[m][0].lower() #hope this works
    string_b = sym_read[m][1]
    string_a = string_a.rstrip() # remove space at right
    string_b = string_b.lstrip()[:-1]
    symbols[string_a] = string_b
    #print(symbols[string_a])
    m +=1 
# now, symbols{} contains dict of symbols:$addr 
cycle_count = 0
branches = 0
# actual parsing
j = startLine-1
while j < endLine:
    current_line = file_read[j].lower() # get line of code n make lowerc
    current_line = current_line[:-1]
    current_line = current_line.lstrip() # strip empty space
    if(len(current_line)>0): # check if not empty
        if current_line[0] != ';' and current_line[0] != '.' and '.db' not in current_line: # if not comment or processor directive 
            if ';' in current_line: # if there's still a comment
                current_line = current_line.split(';',1)[0]
            if ':' in current_line:
                current_line = current_line.split(':',1)[1]
                current_line = current_line.lstrip()
            # now, go through every entry in .fns
            # and check if 'in current_line'
            # and replace.
            for key in symbols:
                if key in current_line:
                    current_line = current_line.split(' ',1)
                    current_line = current_line[0] + ' ' + symbols[key]
            if ',x' in current_line or ', x' in current_line or ', y' in current_line or ',y' in current_line: #
                cycle_count += 1
            if 'lda' in current_line:
                if current_line[4] == '$':
                    addr = current_line[5:] #hex of add only
                    if addr[2:] != '00': # if not zp
                        cycle_count += 4
                    else: #if zp
                        cycle_count += 3
                else:#immediate
                    if current_line[4] == '(':
                        cycle_count += 3#indexed for 5 min cycles
                    cycle_count += 2
            elif 'bpl' in current_line:
                branches += 1
                cycle_count += 3 # average
            elif 'inc' in current_line:
                cycle_count += 6 #todo for zp
            elif 'cmp' in current_line:
                if current_line[4] == '$':
                    addr = current_line[5:] #hex of add only
                    if addr[2:] != '00': # if not zp
                        cycle_count += 4
                    else: #if zp
                        cycle_count += 3
                else:#immediate
                    if current_line[4] == '(':
                        cycle_count += 3#indexed for 5 min cycles
                    cycle_count += 2
            elif 'bcc' in current_line:
                branches += 1
                cycle_count += 2
            elif 'sta' in current_line:
                if current_line[4] == '$':
                    addr = current_line[5:] #hex of add only
                    if addr[2:] != '00': # if not zp
                        cycle_count += 4
                    else: #if zp
                        cycle_count += 3
                else:#immediate
                    if current_line[4] == '(':
                        cycle_count += 3#indexed for 5 min cycles
                    cycle_count += 2
            elif 'ldx' in current_line:
                if current_line[4] == '$':
                    addr = current_line[5:] #hex of add only
                    if addr[2:] != '00': # if not zp
                        cycle_count += 4
                    else: #if zp
                        cycle_count += 3
                else:#immediate
                    if current_line[4] == '(':
                        cycle_count += 3#indexed for 5 min cycles
                    cycle_count += 2
            elif 'inx' in current_line or 'clc' in current_line:
                cycle_count += 2
            elif 'cpx' in current_line:
                if current_line[4] == '$':
                    addr = current_line[5:] #hex of add only
                    if addr[2:] != '00': # if not zp
                        cycle_count += 4
                    else: #if zp
                        cycle_count += 3
                else:#immediate
                    cycle_count += 2
            elif 'bne' in current_line:
                branches += 1
                cycle_count +=2
            elif 'bcs' in current_line:
                branches += 1
                cycle_count += 2
            elif 'jmp' in current_line:
                cycle_count += 3 # todo indirect
            elif 'jsr' in current_line:
                cycle_count += 6
            elif 'bit' in current_line:
                if current_line[4] == '$':
                    addr = current_line[5:] #hex of add only
                    if addr[2:] != '00': # if not zp
                        cycle_count += 4
                    else: #if zp
                        cycle_count += 3
            elif 'rts' in current_line:
                cycle_count += 6
            elif 'dec' in current_line:
                if current_line[4] == '$':
                    addr = current_line[5:] #hex of add only
                    if addr[2:] != '00': # if not zp
                        cycle_count += 6
                    else: #if zp
                        cycle_count += 5
            elif 'lsr' in current_line or 'rol' in current_line:
                if current_line[4] == '$':
                    addr = current_line[5:] #hex of add only
                    if addr[2:] != '00': # if not zp
                        cycle_count += 6
                    else: #if zp
                        cycle_count += 5
                else:#immediate
                    cycle_count += 2
            elif 'stx' in current_line:
                if current_line[4] == '$':
                    addr = current_line[5:] #hex of add only
                    if addr[2:] != '00': # if not zp
                        cycle_count += 4
                    else: #if zp
                        cycle_count += 3
            elif 'adc' in current_line:
                if current_line[4] == '$':
                    addr = current_line[5:] #hex of add only
                    if addr[2:] != '00': # if not zp
                        cycle_count += 4
                    else: #if zp
                        cycle_count += 3
                else:#immediate
                    if current_line[4] == '(':
                        cycle_count += 3#indexed for 5 min cycles
                    cycle_count += 2
            #else: 
                #print('Not parsed: ' + current_line)
            
    j += 1

print('Counted cycles: ' + str(cycle_count) + ', with '+ str(branches) + ' branches.')
low_cy = cycle_count+(branches*25)
print('Low cycle estimate: ' + str(cycle_count+(branches*25)))
hi_cy = cycle_count+(branches*128)
print('Hi cycle estimate: ' + str(cycle_count+(branches*128)))
avg_cy = (low_cy + hi_cy) / 2
print("\nYou're using about "+ str(math.floor((avg_cy / 6800)*100)) +'%' + " of the VBlank cycles on the NES.\n")