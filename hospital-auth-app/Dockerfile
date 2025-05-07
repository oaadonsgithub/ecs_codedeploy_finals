## Copyright (c) HashiCorp, Inc.
## SPDX-License-Identifier: MPL-2.0


FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 5000

CMD ["node", "index.js"]
