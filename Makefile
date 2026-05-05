# Makefile for Anx CPU FPGA Project
# Target: xc7a35tfgg484-1 (Nexys A7-35T)

# Directories
RTL_DIR = rtl_borad
SCRIPT_DIR = scripts
BUILD_DIR = build
COE_DIR = coe

# Source files
RTL_SRCS = $(wildcard $(RTL_DIR)/*.v)

# Python script for generating COE files
define COE_GEN_SCRIPT
import sys
import os

def asm_to_coe(asm_file, coe_file):
    """Convert assembly to COE file for Block RAM initialization"""

    # Instruction encoding dictionary (LoongArch LA32R)
    inst_enc = {
        'lu12i.w':  0b0001010,
        'addi.w':   0b0000001010,
        'addiw':    0b0000001010,
        'add.w':    0b00000000000100000,
        'nor':      0b00000000000101000,
        'beq':      0b010110,
        'b':        0b010100,
        'st.b':     0b0010100110,
        'st.h':     0b0010100111,
        'st.w':     0b0010100100,
        'ld.b':     0b0010100000,
        'ld.h':     0b0010100001,
        'ld.w':     0b0010100010,
        'sll.w':    0b00000000000101110,
        'slli.w':   0b00000000010000001,
        'slliw':    0b00000000010000001,
    }

    def parse_reg(r):
        """Parse register name to number"""
        r = r.strip().replace('$', '').replace('r', '').replace(',', '')
        return int(r)

    def encode_inst(line):
        """Encode single instruction"""
        line = line.strip()
        if not line or line.startswith('#'):
            return None

        # Remove comments
        if '#' in line:
            line = line.split('#')[0].strip()

        parts = line.replace(',', ' ').split()
        if not parts:
            return None

        op = parts[0].lower()

        # lu12i.w $rd, imm
        if op == 'lu12i.w':
            rd = parse_reg(parts[1])
            imm = int(parts[2], 0) & 0xFFFFF
            inst = (0b0001010 << 25) | (imm << 5) | rd
            return inst

        # addi.w/addiw $rd, $rj, imm
        elif op in ['addi.w', 'addiw']:
            rd = parse_reg(parts[1])
            rj = parse_reg(parts[2])
            imm = int(parts[3], 0) & 0xFFF
            inst = (0b0000001010 << 22) | (imm << 10) | (rj << 5) | rd
            return inst

        # add.w $rd, $rj, $rk
        elif op == 'add.w':
            rd = parse_reg(parts[1])
            rj = parse_reg(parts[2])
            rk = parse_reg(parts[3])
            inst = (0b00000000000100000 << 15) | (rk << 10) | (rj << 5) | rd
            return inst

        # nor $rd, $rj, $rk
        elif op == 'nor':
            rd = parse_reg(parts[1])
            rj = parse_reg(parts[2])
            rk = parse_reg(parts[3])
            inst = (0b00000000000101000 << 15) | (rk << 10) | (rj << 5) | rd
            return inst

        # beq $rj, $rd, offset
        elif op == 'beq':
            rj = parse_reg(parts[1])
            rd = parse_reg(parts[2])
            offset = int(parts[3], 0) & 0xFFFF
            inst = (0b010110 << 26) | (offset << 10) | (rj << 5) | rd
            return inst

        # b offset
        elif op == 'b':
            offset = int(parts[1], 0) & 0x3FFFFFF
            inst = (0b010100 << 26) | offset
            return inst

        # st.b $rd, $rj, imm
        elif op == 'st.b':
            rd = parse_reg(parts[1])
            rj = parse_reg(parts[2])
            imm = int(parts[3], 0) & 0xFFF
            inst = (0b0010100110 << 22) | (imm << 10) | (rj << 5) | rd
            return inst

        # st.w $rd, $rj, imm
        elif op == 'st.w':
            rd = parse_reg(parts[1])
            rj = parse_reg(parts[2])
            imm = int(parts[3], 0) & 0xFFF
            inst = (0b0010100100 << 22) | (imm << 10) | (rj << 5) | rd
            return inst

        # ld.b $rd, $rj, imm
        elif op == 'ld.b':
            rd = parse_reg(parts[1])
            rj = parse_reg(parts[2])
            imm = int(parts[3], 0) & 0xFFF
            inst = (0b0010100000 << 22) | (imm << 10) | (rj << 5) | rd
            return inst

        # slli.w/slliw $rd, $rj, imm
        elif op in ['slli.w', 'slliw']:
            rd = parse_reg(parts[1])
            rj = parse_reg(parts[2])
            imm = int(parts[3], 0) & 0x1F
            inst = (0b00000000010000001 << 15) | (imm << 10) | (rj << 5) | rd
            return inst

        return None

    # Read assembly file
    with open(asm_file, 'r') as f:
        lines = f.readlines()

    # Generate COE file
    with open(coe_file, 'w') as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")

        instructions = []
        for line in lines:
            inst = encode_inst(line)
            if inst is not None:
                instructions.append(inst)

        # Write instructions in hex format
        for i, inst in enumerate(instructions):
            if i == len(instructions) - 1:
                f.write(f"{inst:08x};\n")
            else:
                f.write(f"{inst:08x},\n")

    print(f"Generated {coe_file} with {len(instructions)} instructions")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python coe_gen.py <asm_file> <coe_file>")
        sys.exit(1)

    asm_file = sys.argv[1]
    coe_file = sys.argv[2]
    asm_to_coe(asm_file, coe_file)
endef

# Export the Python script
coe_gen.py:
	@echo "Creating COE generator script..."
	@python3 -c '$(COE_GEN_SCRIPT)' > coe_gen.py 2>/dev/null || echo "$(COE_GEN_SCRIPT)" > coe_gen.py

# Create directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(COE_DIR):
	mkdir -p $(COE_DIR)

# Generate COE file for n45_st_b_test
coe: $(COE_DIR)
	@echo "Generating COE file for n45_st_b_test..."
	@echo 'lu12i.w    $$r14, 0xb4f01' > $(COE_DIR)/n45_st_b_test.asm
	@echo 'addiw      $$r14, $$r14, -1744' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'addiw      $$r13, $$r0, 1' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'st.b       $$r13, $$r14, 0' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'lu12i.w    $$r15, 0xb4f01' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'addiw      $$r15, $$r15, -1782' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'addiw      $$r20, $$r0, 0' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'addiw      $$r20, $$r20, 1' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'slliw      $$r21, $$r20, 2' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'beq        $$r21, $$r0, 3' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'b          -4' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'ld.b       $$r12, $$r15, 0' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'nor        $$r12, $$r12, $$r0' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'st.b       $$r12, $$r15, 0' >> $(COE_DIR)/n45_st_b_test.asm
	@echo 'b          -9' >> $(COE_DIR)/n45_st_b_test.asm
	@python3 -c "
$$(echo '$(COE_GEN_SCRIPT)' | sed 's/\\$$/$$$$/g')
" -- $(COE_DIR)/n45_st_b_test.asm $(COE_DIR)/inst_ram.coe

# Simple hex generation without Python
$(COE_DIR)/inst_ram.coe: $(COE_DIR)
	@echo "Generating inst_ram.coe..."
	@echo "memory_initialization_radix=16;" > $@
	@echo "memory_initialization_vector=" >> $@
	@echo "0280701d," >> $@   # lu12i.w $$r14, 0xb4f01
	@echo "028071cd," >> $@   # addiw $$r14, $$r14, -1744
	@echo "028001ad," >> $@   # addiw $$r13, $$r0, 1
	@echo "298001ae," >> $@   # st.b $$r13, $$r14, 0
	@echo "0280701f," >> $@   # lu12i.w $$r15, 0xb4f01
	@echo "02806f1f," >> $@   # addiw $$r15, $$r15, -1782
	@echo "02800194," >> $@   # addiw $$r20, $$r0, 0
	@echo "02801194," >> $@   # addiw $$r20, $$r20, 1
	@echo "00808595," >> $@   # slliw $$r21, $$r20, 2
	@echo "580015f5," >> $@   # beq $$r21, $$r0, 3
	@echo "50000000," >> $@   # b -4
	@echo "288001ef," >> $@   # ld.b $$r12, $$r15, 0
	@echo "0015018c," >> $@   # nor $$r12, $$r12, $$r0
	@echo "298001ef," >> $@   # st.b $$r12, $$r15, 0
	@echo "53fffffe;" >> $@   # b -9

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -f coe_gen.py

# Help
help:
	@echo "Available targets:"
	@echo "  make coe    - Generate COE file for instruction memory"
	@echo "  make clean  - Clean build artifacts"
	@echo "  make help   - Show this help message"

.PHONY: coe clean help
