FROM node:12-alpine

COPY . /opt/app
WORKDIR /opt/app
RUN npm install --production

ENV PORT=9002
EXPOSE 9002

VOLUME /opt/app/server-data

CMD ["npm", "start"]
