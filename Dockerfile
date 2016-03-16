FROM alpine:3.3

# Install Nginx.
RUN \
    apk update && \
    apk --no-cache add openssl-dev pcre-dev x264-dev zlib-dev wget build-base \
        autoconf automake libtool pkgconfig \
        yasm lame-dev libogg-dev libvpx-dev libvorbis-dev x265-dev freetype-dev libass-dev libwebp-dev \
        rtmpdump-dev libtheora-dev opus-dev && \
    apk add openssl zlib pcre ca-certificates && \
    ln -s /lib/libz.so /usr/lib/.

RUN cd /root && \
  wget http://nginx.org/download/nginx-1.9.2.tar.gz && \
  wget https://github.com/arut/nginx-rtmp-module/archive/master.zip
  
RUN cd /root && \
  tar -zxvf nginx-1.9.2.tar.gz && \
  unzip master.zip

RUN cd /root/nginx-1.9.2 && \
  ./configure \
    --add-module=../nginx-rtmp-module-master \
    --prefix=/etc/nginx \
    --sbin-path=/usr/local/sbin/nginx && \
  make && \
  make install
 
  
RUN mkdir -p /var/log/nginx
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

RUN cd /root && \
    rm nginx-1.9.2.tar.gz && \
    rm master.zip && \
    rm -rf nginx-1.9.2 && \
    rm -rf nginx-rtmp-module-master

# ffmpeg stuff
RUN mkdir /ffmpeg_sources
RUN mkdir /ffmpeg_build

RUN cd /ffmpeg_sources && \
    wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master && \
    tar xzvf fdk-aac.tar.gz && \
    cd mstorsjo-fdk-aac* && \
    autoreconf -fiv && \
    ./configure --prefix="/ffmpeg_build" --disable-shared && \
    make && \
    make install && \
    make distclean
    
RUN cd /ffmpeg_sources && \
    wget http://ffmpeg.org/releases/ffmpeg-3.0.tar.bz2 && \
    tar -jxvf ffmpeg-3.0.tar.bz2 && \
    cd ffmpeg-3.0 && \
    PATH="/bin:$PATH" PKG_CONFIG_PATH="/ffmpeg_build/lib/pkgconfig" ./configure \
      --prefix="/ffmpeg_build" \
      --pkg-config-flags="--static" \
      --extra-cflags="-I/ffmpeg_build/include" \
      --extra-ldflags="-L/ffmpeg_build/lib" \
      --bindir="/bin" \
       --enable-version3 \
      --enable-gpl \
      --enable-nonfree \
      --enable-small \
      --enable-libfdk-aac \
      --enable-libx264 \
       --enable-libmp3lame \
       --enable-libx265 \
       --enable-libvpx \
       --enable-libtheora \
       --enable-libvorbis \
       --enable-libopus \
       --enable-libass \
       --enable-libwebp \
       --enable-librtmp \
       --enable-postproc \
       --enable-avresample \
       --enable-libfreetype \
       --enable-openssl \
       --disable-debug && \
    PATH="/bin:$PATH" make && \
    make install && \
    make distclean && \
    hash -r
  
RUN apk del build-base automake autoconf libtool pcre-dev zlib-dev wget openssl-dev && \
  rm -rf /ffmpeg_sources && \
  rm -rf /tmp/src && \
  rm -rf /var/cache/apk/* && \
  mkdir -p /data/hls

ADD nginx/nginx.conf /etc/nginx/nginx.conf

# Expose ports.
EXPOSE 80 1935
  
# Define working directory.
WORKDIR /etc/nginx

# Define default command.
CMD ["nginx","-c","/etc/nginx/nginx.conf"]
