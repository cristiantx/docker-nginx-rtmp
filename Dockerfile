# Pull base image.
FROM alpine:3.3

# Install Nginx.
RUN \
    apk update && \
    apk --no-cache add --virtual .build-deps openssl-dev pcre-dev zlib-dev wget build-base ca-certificates ffmpeg && \
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

RUN cd /root && \
  wget http://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-0.1.4.tar.gz

RUN cd /root && \
  tar -zxvf fdk-aac-0.1.4.tar.gz
  
RUN cd /root/fdk-aac-0.1.4 && \
  ./configure && \
  make && \
  make install

RUN cd /root && \
    wget http://ffmpeg.org/releases/ffmpeg-3.0.tar.bz2
    
RUN cd /root && \
    tar -xvzf ffmpeg-3.0.tar.bz2
  
RUN apk del build-base && \
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
