# 拉取一个基本 node 运行环境的镜像，作为基础镜像
FROM node:7-alpine


RUN mkdir -p /app
COPY . /app

WORKDIR /app
RUN npm install

EXPOSE 3000

# 开启 node 服务器

CMD ["node", "app.js"]
