#!/bin/sh
DoExitAsm ()
{ echo "An error occurred while assembling $1"; exit 1; }
DoExitLink ()
{ echo "An error occurred while linking $1"; exit 1; }
echo Assembling nonosolver
/Library/Developer/CommandLineTools/usr/bin/clang -x assembler -c -target x86_64-apple-macosx10.8.0 -o /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonosolver.o  -x assembler /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonosolver.s
if [ $? != 0 ]; then DoExitAsm nonosolver; fi
rm /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonosolver.s
echo Assembling nonogramgame
/Library/Developer/CommandLineTools/usr/bin/clang -x assembler -c -target x86_64-apple-macosx10.8.0 -o /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonogramgame.o  -x assembler /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonogramgame.s
if [ $? != 0 ]; then DoExitAsm nonogramgame; fi
rm /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonogramgame.s
echo Assembling gamedisplay
/Library/Developer/CommandLineTools/usr/bin/clang -x assembler -c -target x86_64-apple-macosx10.8.0 -o /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/gamedisplay.o  -x assembler /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/gamedisplay.s
if [ $? != 0 ]; then DoExitAsm gamedisplay; fi
rm /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/gamedisplay.s
echo Assembling nonoform
/Library/Developer/CommandLineTools/usr/bin/clang -x assembler -c -target x86_64-apple-macosx10.8.0 -o /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonoform.o  -x assembler /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonoform.s
if [ $? != 0 ]; then DoExitAsm nonoform; fi
rm /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonoform.s
echo Assembling nonoproj
/Library/Developer/CommandLineTools/usr/bin/clang -x assembler -c -target x86_64-apple-macosx10.8.0 -o /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonoProj.o  -x assembler /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonoProj.s
if [ $? != 0 ]; then DoExitAsm nonoproj; fi
rm /Users/cloudsoft/Code/nonogram/lib/x86_64-darwin/nonoProj.s
echo Linking /Users/cloudsoft/Code/nonogram/nonoProj
OFS=$IFS
IFS="
"
/Library/Developer/CommandLineTools/usr/bin/ld     -framework Cocoa      -order_file /Users/cloudsoft/Code/nonogram/symbol_order.fpc -multiply_defined suppress -L. -o /Users/cloudsoft/Code/nonogram/nonoProj `cat /Users/cloudsoft/Code/nonogram/link6893.res` -filelist /Users/cloudsoft/Code/nonogram/linkfiles6893.res
if [ $? != 0 ]; then DoExitLink /Users/cloudsoft/Code/nonogram/nonoProj; fi
IFS=$OFS
