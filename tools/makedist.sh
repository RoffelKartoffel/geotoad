#!/bin/sh
# Builds a new release of geotoad
# $Id: makedist.se,v 1.3 2002/04/23 04:05:41 helix Exp $

src_dir="/tmp/namebench-$$"
svn checkout http://geotoad.googlecode.com/svn/trunk/ $src_dir
cd $src_dir

if [ ! -f VERSION ];  then
  echo "VERSION not found"
  exit 2
fi
VERSION=`cat VERSION`
DISTNAME="geotoad-$VERSION"
DEST=$HOME/Desktop/GeoToad
GENERIC_DIR=$DEST/$DISTNAME
GENERIC_PKG="${GENERIC_DIR}.zip"

MAC_DIR="$DEST/GeoToad for Mac"
MAC_PKG="$DEST/${DISTNAME}_MacOSX.dmg"

WIN_DIR=$DEST/${DISTNAME}_for_Windows
WIN_PKG="$DEST/${DISTNAME}_Windows.zip"

echo "Erasing old distributions."
rm -Rf "$DEST"

echo "Creating $GENERIC_DIR"
mkdir -p "$GENERIC_DIR"
rsync -a --exclude ".svn/" . $GENERIC_DIR

sed s/"%VERSION%"/"$VERSION"/g geotoad.rb > $GENERIC_DIR/geotoad.rb
sed s/"%VERSION%"/"$VERSION"/g README.txt > $GENERIC_DIR/README.txt
sed s/"%VERSION%"/"$VERSION"/g FAQ.txt > $GENERIC_DIR/FAQ.txt
chmod 755 $GENERIC_DIR/*.rb
rm $GENERIC_DIR/VERSION $GENERIC_DIR/tools/countryrip.rb $GENERIC_DIR/tools/*.sh

# Make a duplicate of it for Macs before we nuke the .command file
cp -Rp $GENERIC_DIR "$MAC_DIR"
rm $GENERIC_DIR/*.command
ln -s geotoad.rb geotoad
cd "$DEST"
zip -r "$GENERIC_PKG" "$DISTNAME"

# Mac OS X
if [ -d "/Applications" ]; then
  echo "Creating $MAC_DIR"
  rm "$MAC_DIR/geotoad"
  cd "$MAC_DIR" 
  sips -i data/bufos-icon.icns && DeRez -only icns data/bufos-icon.icns > data/icns.rsrc
  Rez -append data/icns.rsrc -o "GeoToad for Mac.command"
  SetFile -a E "GeoToad for Mac.command"
  SetFile -a C "GeoToad for Mac.command"
  rm data/icns.rsrc
  echo "Creating $MAC_PKG"
  hdiutil create -srcfolder "$MAC_DIR" "$MAC_PKG"
  echo "done with $MAC_PKG"
else
  echo "Skipping Mac OS X release"
fi

# Windows
if [ -r "/usr/local/bin/rubyscript2ex.rb" ]; then
  echo "Creating $WIN_DIR"
  cp -Rp "$GENERIC_DIR" "$WIN_DIR"
  rm "$WIN_DIR/geotoad"
  cd "$WIN_DIR"
  mkdir compile
  mv *.rb lib interface data compile
  mv compile/geotoad.rb compile/init.rb
  flip -d *.txt
  perl -pi -e 's/([\s])geotoad\.rb/$1geotoad/g' README.txt

  echo "In Windows, run: ruby rubyscript2exe.rb compile/init.rb"
  read ENTER
  if [ -f "compile.exe" ]; then
    mv compile.exe geotoad.exe
    mv compile/data .
    rm -Rf "$WIN_DIR/compile"
    zip -r "$WIN_PKG" *
  else
    echo "compile.exe not found"
  fi
else
  echo "Skipping Windows Release"
fi

