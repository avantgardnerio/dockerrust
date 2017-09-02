# https://gregkatz.github.io/2017-05-20-rust-emscripten.html

FROM ubuntu:xenial

RUN apt-get update && \
	apt-get install -y \
	curl \
	git \
	python

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" 
RUN rustup override set 1.20.0

RUN rustup target add asmjs-unknown-emscripten
RUN rustup target add wasm32-unknown-emscripten

RUN curl -O https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz
RUN tar -xzf emsdk-portable.tar.gz

RUN apt-get install -y \
	build-essential \
	cmake

RUN cd emsdk-portable && \
	./emsdk update && \
	./emsdk install sdk-tag-1.37.18-64bit && \
	./emsdk activate sdk-tag-1.37.18-64bit 

ENV PATH="/emsdk-portable:/emsdk-portable/clang/tag-e1.37.18/build_tag-e1.37.18_64/bin:/emsdk-portable/node/4.1.1_64bit/bin:/emsdk-portable/emscripten/tag-1.37.18:/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN git clone https://github.com/bgard6977/cvsolitaire.git

RUN apt-get install -y \
	libsdl2-dev \
	nano \
	vim

RUN echo 'emcc "-s" "USE_SDL=2" "-o" "cvsolitaire.html" "-02" "-s" "NO_EXIT_RUNTIME=1" $@' > /cvsolitaire/emcc_sdl
RUN chmod ugo+x /cvsolitaire/emcc_sdl
RUN mkdir -p /cvsolitaire/.cargo
RUN echo '[target.wasm32-unknown-emscripten]\nlinker = "/cvsolitaire/emcc_sdl"\n\n[target.asmjs-unknown-emscripten]\nlinker = "/cvsolitaire/emcc_sdl"\n' > /cvsolitaire/.cargo/config

RUN cd cvsolitaire && cargo build --target=asmjs-unknown-emscripten --release

RUN npm install -g http-server

ENTRYPOINT http-server /cvsolitaire
