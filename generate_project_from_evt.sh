#!/bin/bash

PART_LIST="./ch32f-parts-list.txt"

# if no arg,
if [ $# -ne 1 ]; then
  echo "usage: gen_makefile <part>" 
  echo "please specify the ch32f part your use:"
  while IFS= read -r line
  do
    part=$(echo "$line"|awk -F ' ' '{print $1}'| tr '[:upper:]' '[:lower:]')
    echo "$part"
  done < "$PART_LIST"
  exit
fi

# iterate the part list to found part info.
PART=$1
FLASHSIZE=
RAMSIZE=
STARTUP_ASM=
ZIPFILE=

FOUND="f"

while IFS= read -r line
do
  cur_part=$(echo "$line"|awk -F ' ' '{print $1}'| tr '[:upper:]' '[:lower:]')
  FLASHSIZE=$(echo "$line"|awk -F ' ' '{print $2}')
  RAMSIZE=$(echo "$line"|awk -F ' ' '{print $3}')
  STARTUP_ASM=$(echo "$line"|awk -F ' ' '{print $4}')
  ZIPFILE=$(echo "$line"|awk -F ' ' '{print $5}')
  if [ "$cur_part""x" == "$PART""x" ]; then
    FOUND="t"
    break;
  fi
done < "$PART_LIST"

#if not found
if [ "$FOUND""x" == "f""x" ];then
  echo "Your part is not supported."
  exit
fi

# found
echo "Convert project for $PART"
echo "part : $PART"
echo "flash size : $FLASHSIZE"
echo "ram size : $RAMSIZE"
echo "#########################"

# clean
rm -rf evt_tmp
# remove all sources, copy from EVT later
rm -rf CMSIS Debug Startup StdPeriphDriver User Examples
# remove Linker script, generate according to part info.
rm -rf Ld

echo "Extract EVT package"
mkdir -p evt_tmp
unzip -q -O gb18030 $ZIPFILE -d evt_tmp

# prepare dir structure
cp -r evt_tmp/EVT/EXAM/SRC/CMSIS .
cp -r evt_tmp/EVT/EXAM/SRC/Debug .
cp -r evt_tmp/EVT/EXAM/SRC/Startup .
cp -r evt_tmp/EVT/EXAM/SRC/StdPeriphDriver .
cp -r evt_tmp/EVT/EXAM/GPIO/GPIO_Toggle ./User

# prepare examples
mkdir -p Examples
cp -r evt_tmp/EVT/EXAM/* Examples
rm -rf Examples/SRC

# drop evt
rm -rf evt_tmp

echo "Generate linker script"
# generate the Linker script
mkdir -p Ld
cp Link.template.ld Ld/Link.ld
sed -i "s/FLASH_SIZE/$FLASHSIZE/g" Ld/Link.ld
sed -i "s/RAM_SIZE/$RAMSIZE/g" Ld/Link.ld

# convert startup asm.
echo "Convert startup file"
cd Startup
../startupfile_generator.py $STARTUP_ASM
rm -f *.s
cd ..

# Fix source codes... 
echo "Patch sources"
# for 103 evt
if [[ $PART = ch32f1* ]]; then
  sed -i "s/define\t__PACKED\t\t\t__packed/define __PACKED __attribute__((packed))/g" StdPeriphDriver/inc/ch32f10x_usb.h
  sed -i "s/__packed/__PACKED/g" StdPeriphDriver/inc/ch32f10x_usb.h
  
  sed -i "s/__align( 4 )/__attribute__((aligned(4)))/g" StdPeriphDriver/src/ch32f10x_usb_host.c
  
  sed -i "s/unsigned int SystemCoreClock/uint32_t SystemCoreClock/g" User/system_ch32f10x.h
fi

# for ch32f203evt
if [[ $PART = ch32f2* ]]; then
  sed -i "s/ch32F20x.h/ch32f20x.h/g" StdPeriphDriver/inc/ch32f20x_opa.h
fi

# for both 103 and 203 evt
sed -i "s/\"strexh %0, %2, \[%1\]\" \: \"=r\"/\"strexh %0, %2, \[%1\]\" \: \"=\&r\"/g"  CMSIS/core_cm3.c
sed -i "s/\"strexb %0, %2, \[%1\]\" \: \"=r\"/\"strexb %0, %2, \[%1\]\" \: \"=\&r\"/g"  CMSIS/core_cm3.c

echo "Generate Makefile"
# collect c files and asm files
find . -path ./Examples -prune -o -type f -name "*.c"|sed 's@^\./@@g;s@$@ \\@g' > c_source.list
find . -path ./Examples -prune -o -name \*.S|sed 's@^\./@@g;s@$@ \\@g'|head -n 1 > startup_asm_source.list

# drop Examples line in source list.
sed -i "/^Examples/d" c_source.list

sed "s/C_SOURCE_LIST/$(sed -e 's/[\&/]/\\&/g' -e 's/$/\\n/' c_source.list | tr -d '\n')/" Makefile.ch32ftemplate >Makefile
sed -i "s/STARTUP_ASM_SOURCE_LIST/$(sed -e 's/[\&/]/\\&/g' -e 's/$/\\n/' startup_asm_source.list | tr -d '\n'|head -n 1)/" Makefile

rm -f c_source.list startup_asm_source.list

sed -i "s/CH32FXXX/$PART/g" Makefile

# use nano.specs directly.
#if [ "$PART""x" == "ch32f103c6t6""x" ]; then 
#sed -i "s/\$(MCU) -specs=nosys.specs/\$(MCU) -specs=nano.specs -specs=nosys.specs/g" Makefile
#fi

echo "#########################"
echo "Done, project generated, type 'make' to build"

