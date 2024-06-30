FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt install -y build-essential git zip && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/envenomator/agon-ez80asm && (cd agon-ez80asm && make -j8 && cp bin/ez80asm /bin/ && cd .. && rm -rf agon-ez80asm)

WORKDIR /src

CMD ["ez80asm"]