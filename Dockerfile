FROM gliderlabs/alpine:latest

# Install Nginx.
RUN \
    apk update && \
    apk --no-cache add --virtual .build-deps openssl-dev pcre-dev yasm x264-dev fdk-aac-dev \
        zlib-dev wget build-base ca-certificates autoconf automake libtool && \
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
    rm master.zip

# ffmpeg stuff
RUN mkdir /ffmpeg_sources
RUN mkdir /ffmpeg_build

    
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
      --enable-gpl \
      --enable-libfdk-aac \
      --enable-libx264 \
      --enable-nonfree && \
    PATH="/bin:$PATH" make && \
    make install && \
    make distclean && \
    hash -r
  
RUN apk del build-base automake autoconf libtool && \
  rm -rf /ffmpeg_sources && \
  rm -rf /tmp/src && \
  rm -rf /var/cache/apk/* && \
  mkdir -p /data/hls

ADD nginx.conf /etc/nginx/nginx.conf

# Expose ports.
EXPOSE 80 1935
  
# Define working directory.
WORKDIR /etc/nginx

# Define default command.
CMD ["nginx","-c","/etc/nginx/nginx.conf"]
