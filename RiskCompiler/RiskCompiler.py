assembly_to_bin = {
    "LOAD": "0001",
    "STORE": "0010",
    "LOADI": "0011",
    "STOREI": "0100",
}

register_address = {
    "R1": "0001",
    "R2": "0010",
    "R3": "0011",
    "R4": "0100",
}


def assemble_instruction(instruction):
    parts = instruction.split()

    opcode = assembly_to_bin.get(parts[0].upper(), None)
    register = register_address.get(parts[1].upper(), None)
    add_imm = f"{int(parts[2]):08b}"

    return f"{opcode}{register}{add_imm}"


input_file = "assembly.txt"
output_file = "machine_code.txt"

with open(input_file, "r") as infile, open(output_file, "w") as outfile:
    for line in infile:
        binary = assemble_instruction(line)
        if binary:
            outfile.write(binary + "\n")
