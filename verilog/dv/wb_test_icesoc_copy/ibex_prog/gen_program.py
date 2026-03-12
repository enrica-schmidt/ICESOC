import sys

binname = str(sys.argv[1])
binfile = open(binname, 'rb')
pro_data = binfile.read()
pro_len = int(len(pro_data)/4)
binfile.close()

fileout = str(sys.argv[2])
hfile   = open(fileout, 'w')

hfile.write("#ifndef IBEX_PROG_H\n")
hfile.write("#define IBEX_PROG_H\n")
hfile.write("#include <stdint.h>\n")
hfile.write("#define PROGRAM_LENGTH " + str(pro_len) + "\n")
hfile.write("const uint32_t program_data[" + str(pro_len) +'] ={ \n')
for i in range(pro_len):
    if i != pro_len-1:
        hfile.write("       " + hex(int.from_bytes(pro_data[4*i:4*(i+1)], byteorder='little')) + ', \n')
    else :
        hfile.write("       " + hex(int.from_bytes(pro_data[4*i:4*(i+1)], byteorder='little')) + ' }; \n')

hfile.write("#endif /* IBEX_PROG_H */\n")
hfile.close()

