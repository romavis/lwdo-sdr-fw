#!/usr/bin/env python3

import re
import os
import sys

def indent_block(lines, indent):
    prefix = ' ' * indent
    lines = [prefix + l for l in lines]
    return lines


def main():
    if len(sys.argv) != 3:
        print('Usage: gen.py REGS_NAME HEADER.H', file=sys.stderr)
        return 1

    regs_name = sys.argv[1].upper().strip()
    header = sys.argv[2]

    with open(header, 'r') as f:
        lines = f.read().splitlines()

    re_define = re.compile(fr'^#define\s+{re.escape(regs_name)}_(?P<name>\w+)\s+(?P<value>\w+)$', re.ASCII)
    regs = {}
    reg = ''
    for l in lines:
        l = l.strip()
        m = re_define.fullmatch(l)
        if m:
            name = m.group('name')
            value = m.group('value')
            # Determine if this is a register spec or bitfield spec
            mreg = re.fullmatch(r'(\w+)_BYTE_(\w+)', name, re.ASCII)
            mbit = None
            if reg:
                mbit = re.fullmatch(fr'{re.escape(reg)}_(\w+)_BIT_(\w+)', name, re.ASCII)
            if mreg:
                reg = mreg.group(1)
                prop = mreg.group(2)
                if reg not in regs:
                    regs[reg] = {}
                    regs[reg]['fields'] = {}
                regs[reg][prop] = value
            elif mbit:
                bf = mbit.group(1)
                prop = mbit.group(2)
                fields = regs[reg]['fields']
                if bf not in fields:
                    fields[bf] = {}
                fields[bf][prop] = value
            else:
                print(f'WARNING - ignoring definition: {l!r}', file=sys.stderr)
    # Code generation options
    indent = 2
    guard = f'H_{regs_name}_HPP__'
    classname = regs_name
    bfclass = 'lwdo::regs::BitfieldDef'
    # Generate C++ code and print to stdout
    out = []
    out.append('// WARNING: auto-generated file, do not edit!')
    out.append('')
    out.append(f'#ifndef {guard}')
    out.append(f'#define {guard}')
    out.append('')
    out.append(f'struct {classname} {{')
    b = []
    # Import bitfield template
    b.append('template <uint32_t RA, unsigned RW, unsigned BO, unsigned BW>')
    b.append(f'using BF = {bfclass}<RA, RW, BO, BW>;')
    b.append('')
    # Print fields
    for rname, rprops in regs.items():
        raddr = int(rprops['OFFSET'], 0)
        rsize = int(rprops['WIDTH'], 0)
        b.append(f'// {rname} @ 0x{raddr:04x}')
        for fname, fprops in rprops['fields'].items():
            faddr = int(fprops['OFFSET'], 0)
            fsize = int(fprops['WIDTH'], 0)
            b.append(f'static constexpr BF<0x{raddr:04x}, {rsize}, {faddr}, {fsize}> {rname}_{fname}{{}};')
    out.extend(indent_block(b, indent))
    out.append(f'}};')
    out.append('')
    out.append(f'#endif  // {guard}')
    out.append('')
    print('\n'.join(out))


if __name__ == '__main__':
    main()
