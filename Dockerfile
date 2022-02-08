FROM centos:7 as builder

ENV NGINX_VERSION 1.16.1
ENV SRPM_URL http://nginx.org/packages/centos/7/SRPMS/nginx-${NGINX_VERSION}-1.el7.ngx.src.rpm

RUN yum makecache fast \
 && yum groupinstall Development tools -y \
 && yum install openssl-devel zlib-devel pcre-devel -y \
 && yum clean all -y \
 && rm -rf /var/cache/yum

RUN rpm -i ${SRPM_URL} \
 && tar zxf /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}.tar.gz -C /root/rpmbuild/SOURCES/ \
 && rm -f /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}.tar.gz \
 && mkdir -p /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}/src/nginx-upstream-fair \
 && git clone https://github.com/gnosek/nginx-upstream-fair.git /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}/src/nginx-upstream-fair \
 && mkdir -p /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}/src/headers-more-nginx-module \
 && git clone https://github.com/openresty/headers-more-nginx-module.git /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}/src/headers-more-nginx-module \
 && sed -e '131 a\    in_port_t                        default_port;' \
        -i /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}/src/http/ngx_http_upstream.h \
 && tar zcf /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}.tar.gz -C /root/rpmbuild/SOURCES/ nginx-${NGINX_VERSION} \
 && rm -rf /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION} \
 && sed -e '115 a\    --add-module=src/nginx-upstream-fair \\\n    --add-module=src/headers-more-nginx-module \\' \
        -e '122 s/$/& \\/' \
        -e '122 a\    --add-module=src/nginx-upstream-fair \\\n    --add-module=src/headers-more-nginx-module' \
        -i /root/rpmbuild/SPECS/nginx.spec \
 && rpmbuild -ba /root/rpmbuild/SPECS/nginx.spec
 
RUN openssl_zlib_pcre_extras=' \
     keyutils-libs-devel \
     libcom_err-devel \
     libkadm5 x86_64 \
     libsepol-devel \
     libverto-devel \
 ' \
 && dev_tools_extras=' \
     apr \
     apr-util \
     avahi-libs \
     boost-date-time \
     boost-system \
     boost-thread \
     bzip2 \
     cpp \
     dwz \
     dyninst \
     efivar-libs \
     emacs-filesystem \
     file \
     fipscheck \
     fipscheck-lib \
     gdb \
     gettext-common-devel \
     gettext-libs \
     glibc-devel \
     glibc-headers \
     gnutls \
     groff-base \
     kernel-debug-devel \
     kernel-headers \
     less \
     libcroco \
     libdwarf \
     libedit \
     libgfortran \
     libgomp \
     libmodman \
     libmpc \
     libproxy \
     libquadmath \
     libquadmath-devel \
     libstdc++-devel \
     libunistring \
     m4 \
     mokutil \
     mpfr \
     neon \
     nettle \
     openssh \
     openssh-clients \
     pakchois \
     perl \
     perl-Carp \
     perl-Data-Dumper \
     perl-Encode \
     perl-Error \
     perl-Exporter \
     perl-File-Path \
     perl-File-Temp \
     perl-Filter \
     perl-Getopt-Long \
     perl-HTTP-Tiny \
     perl-PathTools \
     perl-Pod-Escapes \
     perl-Pod-Perldoc \
     perl-Pod-Simple \
     perl-Pod-Usage \
     perl-Scalar-List-Utils \
     perl-Socket \
     perl-Storable \
     perl-TermReadKey \
     perl-Test-Harness \
     perl-Text-ParseWords \
     perl-Thread-Queue \
     perl-Time-HiRes \
     perl-Time-Local \
     perl-XML-Parser \
     perl-constant \
     perl-libs \
     perl-macros \
     perl-parent \
     perl-podlators \
     perl-srpm-macros \
     perl-threads \
     perl-threads-shared \
     python-srpm-macros \
     rsync \
     subversion-libs \
     systemd-sysv \
     systemtap-client \
     systemtap-devel \
     systemtap-runtime \
     trousers \
     unzip \
     zip \
 ' \
 && yum remove openssl-devel zlib-devel pcre-devel $openssl_zlib_pcre_extras -y \
 && yum groupremove Development tools -y \
 && yum remove $dev_tools_extras -y \
 && yum clean all -y \
 && rm -rf /var/cache/yum
 
 
FROM centos:7
 
ENV NGINX_VERSION 1.16.1
 
COPY --from=builder /root/rpmbuild/RPMS/x86_64/nginx-${NGINX_VERSION}-1.el7.ngx.x86_64.rpm .
COPY --from=builder /root/rpmbuild/SRPMS/nginx-${NGINX_VERSION}-1.el7.ngx.src.rpm .
