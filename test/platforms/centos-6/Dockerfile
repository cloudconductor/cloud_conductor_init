FROM <%= @image %>
<% if @http_proxy %>
ENV http_proxy <%= @http_proxy %>
<% if @https_proxy %>
ENV https_proxy <%= @https_proxy %>
<% end %>
<% end %>
ENV LANG <%= @lang %>

<% if @http_proxy %>
RUN echo "proxy=<%= @http_proxy %>" >> /etc/yum.conf
<% end %>
<% if @yum_conf && @yum_conf[:include_only] %>
RUN echo "include_only=<%= @yum_conf[:include_only] %>" >> /etc/yum/pluginconf.d/fastestmirror.conf
<% end %>
RUN yum clean all
RUN yum install -y sudo openssh-server openssh-clients which curl htop
RUN yum install -y git wget tar

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN mkdir -p /var/run/sshd
RUN useradd -d /home/<%= @username %> -m -s /bin/bash <%= @username %>
RUN echo <%= "#{@username}:#{@password}" %> | chpasswd
RUN echo '<%= @username %> ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN yum -y install make gcc gcc-c++ autoconf

RUN curl -L http://www.opscode.com/chef/install.sh | bash
ENV PATH ${PATH}:/opt/chef/embedded/bin
RUN gem install berkshelf

RUN touch ./dummy_iptables
RUN cp ./dummy_iptables /etc/init.d/iptables

# proxy
<% if @http_proxy %>
RUN echo "export http_proxy=<%= @http_proxy %>" >> /etc/profile.d/proxy.sh
<% if @https_proxy %>
RUN echo "export https_proxy=<%= @https_proxy %>" >> /etc/profile.d/proxy.sh
<% end %>
RUN echo "export no_proxy=127.0.0.1,localhost" >> /etc/profile.d/proxy.sh

RUN echo "export http_proxy=<%= @http_proxy %>" >> /etc/wgetrc
<% if @https_proxy %>
RUN echo "export https_proxy=<%= @https_proxy %>" >> /etc/wgetrc

RUN git config --global http.proxy <%= @http_proxy %>
RUN git config --global https.proxy <%= @https_proxy %>
<% end %>
<% end %>
