FROM nginx:latest 
MAINTAINER tricep-overhead@gmail.com
RUN apt update
RUN apt install -y curl net-tools jq 
COPY index.html /usr/share/nginx/html/
COPY scorekeeper.js /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/
CMD ["nginx", "-g", "daemon off;"]
