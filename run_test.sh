#!/bin/bash

# make 'n' shit
make clean
clear
make bin/c_compiler

echo ""

# print out compiled assembly in terminal
./bin/c_compiler<test.c

# saved compiled assembly in .s file
./bin/c_compiler<test.c > main.s

# execute my generated assembly
mips-linux-gnu-gcc -static -Wall main.s -o a.out
qemu-mips a.out

# gcc compiles same code
mips-linux-gnu-gcc -c -S test.c

mkdir -p working

for DRIVER in test_deliverable/testcases/*_driver.c ; do
    NAME=$(basename $DRIVER _driver.c)
    TESTCODE=test_deliverable/testcases/$NAME.c

    >&2 echo "Test case $NAME"

    # Compile driver with normal GCC
    mips-linux-gnu-gcc -c $DRIVER -o working/${NAME}_driver.o 2> working/${NAME}_driver.compile.stderr
    if [[ $? -ne 0 ]]; then
        >&2 echo "ERROR : Couldn't compile driver program using GCC."
        continue
    fi

    # Compile test function with compiler under test to assembly
    cat $TESTCODE | $COMPILER > working/$NAME.s  2> working/${NAME}.compile.stderr
    if [[ $? -ne 0 ]]; then
        >&2 echo "ERROR : Compiler returned error message."
        continue
    fi

    # Link driver object and assembly into executable
    mips-linux-gnu-gcc -static working/${NAME}.s working/${NAME}_driver.o -o working/${NAME}.elf 2> working/${NAME}.link.stderr
    if [[ $? -ne 0 ]]; then
        >&2 echo "ERROR : Linker returned error message."
        continue
    fi

    # Run the actual executable
    qemu-mips working/${NAME}.elf
    result=$?
    if [[ $result -ne 0 ]]; then
        >&2 echo "ERROR : Testcase returned $result, but expected 0."
    else
        echo "pass"
    fi

done
