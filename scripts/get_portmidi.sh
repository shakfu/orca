PREFIX=`pwd`/build/deps

mkdir -p build/downloads && \
	cd build/downloads && \
	git clone https://github.com/PortMidi/portmidi.git && \
	cd portmidi && \
	mkdir build && \
	cd build && \
	cmake .. -DBUILD_SHARED_LIBS=OFF && \
	cmake --build . && \
	cmake --install . --prefix ${PREFIX}
