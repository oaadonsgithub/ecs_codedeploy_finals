# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


FROM python:3.10
WORKDIR /app
COPY . .
RUN pip install poetry && poetry install
CMD ["poetry", "run", "gunicorn", "karrio.wsgi:application", "-b", "0.0.0.0:8000"]
