rm -rf build
mkdir build
chmod 755 build
cd build
cmake .. -DDOPARSE=TRUE
make VERBOSE=1

