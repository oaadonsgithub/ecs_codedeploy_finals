# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


FROM node:18

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]