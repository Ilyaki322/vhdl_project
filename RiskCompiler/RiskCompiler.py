assembly_to_bin = {
    "NOP":   "0000",
    "LOAD":  "0001",
    "STORE": "0010",
    "LOADI": "0011",
    "ADD":   "0100",
    "SUB":   "0101",
    "MUL":   "0110",
    "OR":    "0111",
    "AND":   "1000",
    "XOR":   "1001",
    "SHL":   "1010",
    "SHR":   "1011",
    "CMP":   "1100",
    "MOV":   "1101",
}

register_address = {
    "R1": "0001",
    "R2": "0010",
    "R3": "0011",
    "R4": "0100",
}


def assemble_instruction(instruction):
    parts = instruction.split()

    if len(parts) == 1:
        return "0000000000000000"
    if len(parts) == 2:
        opcode = assembly_to_bin.get(parts[0].upper(), None)
        register = register_address.get(parts[1].upper(), None)
        return f"{opcode}{register}{register}0000"
    if len(parts) == 3:
        opcode = assembly_to_bin.get(parts[0].upper(), None)
        register = register_address.get(parts[1].upper(), None)
        if parts[0] == 'CMP':
            register2 = register_address.get(parts[2].upper(), None)
            return f"{opcode}0000{register}{register2}"
        if parts[0] == 'MOV':
            register2 = register_address.get(parts[2].upper(), None)
            return f"{opcode}{register}{register2}0000"
        add_imm = f"{int(parts[2]):08b}"
        return f"{opcode}{register}{add_imm}"
    if len(parts) == 4:
        opcode = assembly_to_bin.get(parts[0].upper(), None)
        target = register_address.get(parts[1].upper(), None)
        register1 = register_address.get(parts[2].upper(), None)
        register2 = register_address.get(parts[3].upper(), None)
        return f"{opcode}{target}{register1}{register2}"


input_file = "assembly.txt"
output_file = "machine_code.txt"


with open(input_file, "r") as infile, open(output_file, "w") as outfile:
    outfile.write("0000000000000000" + "\n")
    for line in infile:
        binary = assemble_instruction(line)
        if binary:
            outfile.write(binary + "\n")

