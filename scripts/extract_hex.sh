#!/bin/bash

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
    echo "Uso: $0 <input_elf> <output_imem_0> <output_imem_1>"
    exit 1
fi

if [ -z "$TOOLCHAIN_PREFIX" ]; then
    TOOLCHAIN_PREFIX=riscv32-unknown-elf
fi;

# Estrazione dell'output di objdump
OBJDUMP_OUT=$($TOOLCHAIN_PREFIX-objdump -D -w "$1")

# Estrazione della sezione .text_0 (tutto su una riga)
echo "$OBJDUMP_OUT" | awk '/\.text_0:/ {d=1; next} /Disassembly of section/ {d=0} d && !/:$/ && $2 ~ /^[0-9a-fA-F]+$/ {print $2}' > "$2"

# Estrazione della sezione .text_1 (tutto su una riga)
echo "$OBJDUMP_OUT" | awk '/\.text_1:/ {d=1; next} /Disassembly of section/ {d=0} d && !/:$/ && $2 ~ /^[0-9a-fA-F]+$/ {print $2}' > "$3"

exit 0