# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


FROM node:18
WORKDIR /app
COPY . .
RUN npm install && npm run build
EXPOSE 3000
CMD ["npm", "start"]
