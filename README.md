# docker-typecho
caddy+php-fpm+typecho+sqlite一键包

# 使用方法

`docker run -e DOMAIN=example.org -e EMAIL=your@email.com -d --restart=always --name=typecho -v /home/typecho:/srv -p 80:80 -p 443:443 -p 443:443/udp moderras/typecho`

将`example.org`替换为自己的服务器域名, 然后将`your@email.com`替换成你的邮箱就可以了， 如果不想用域名启动， 那就不加DOMAIN环境变量， 这个容器会自己运行在80端口上
