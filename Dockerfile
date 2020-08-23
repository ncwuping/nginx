FROM centos:7

ENV NGINX_VERSION 1.16.1
ENV SRPM_URL http://nginx.org/packages/centos/7/SRPMS/nginx-${NGINX_VERSION}-1.el7.ngx.src.rpm

RUN yum clean all -y \
 && yum makecache fast \
 && yum update -y \
 && yum groupinstall Development tools -y \
 && yum install openssl-devel zlib-devel pcre-devel -y \
 && yum clean all -y \
 && rm -rf /var/cache/yum

RUN rpm -i ${SRPM_URL} \
 && mkdir -p /usr/src/nginx-upstream-fair \
 && git clone https://github.com/gnosek/nginx-upstream-fair.git /usr/src/nginx-upstream-fair \
 && tar zxf /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}.tar.gz -C /root/rpmbuild/SOURCES/ \
 && rm -f /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}.tar.gz \
 && sed -e '131 a\    in_port_t                        default_port;' \
        -i /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}/src/http/ngx_http_upstream.h \
 && tar -C /root/rpmbuild/SOURCES/ -zcf /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION}.tar.gz nginx-${NGINX_VERSION} \
 && rm -rf /root/rpmbuild/SOURCES/nginx-${NGINX_VERSION} \
 && sed -e '115 a\    --add-module=/usr/src/nginx-upstream-fair \\' \
        -e '122,122s/$/& \\/' \
        -e '122 a\    --add-module=/usr/src/nginx-upstream-fair ' \
        -i /root/rpmbuild/SPECS/nginx.spec \
 && rpmbuild -ba /root/rpmbuild/SPECS/nginx.spec
 
RUN yum remove openssl-devel zlib-devel pcre-devel -y \
 && yum groupremove Development tools -y
