# WCH CH32F EVT with GCC and Makefile support

This is a project template with related tools to convert WCH official CH32F EVT package to a GCC and Makefile project.

The official CH32F EVT packages is designed for MDK ARM, and can not get build with gcc, also lack Makefile support.

To make it build with gcc:
- The startup file need convert to the format gcc supported.
- A linker script to match the part you use.
- Should have a 'Makefile'

This template will do above job automatically, and support All CH32F EVT packages from WCH, include:
- CH32F103EVT.ZIP
  + CH32F103C6T6
  + CH32F103C8U6
  + CH32F103C8T6
  + CH32F103R8T6
- CH32F20xEVT.ZIP
  + CH32F203C6T6
  + CH32F203K8T6
  + CH32F203C8T6
  + CH32F203C8U6
  + CH32F203CBT6
  + CH32F203RCT6
  + CH32F203VCT6
  + CH32F205RBT6
  + CH32F207VCT6
  + CH32F208RBT6
  + CH32F208WBU6

## Usage

Assume you already have 'arm-none-eabi-gcc' toolchain installed. to generate a gcc/makefile project for specific part, type:
```
./generate_project_from_evt.sh <part>
```

If you do not know which part you should specify, please run `./generate_project_from_evt.sh` directly for help.

After project generated, there is a 'User' dir contains the codes you should write or modify. By default, it use the 'GPIO_Toggle' example from EVT package.

Then type `make` to build the project.

The `<part>.elf` / `<part>.bin` / `<part>.hex` will be generated at 'build' dir and can be programmed to target device later.






