FROM node:20 AS build

WORKDIR /app

RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

COPY visualize/package.json visualize/package-lock.json ./
RUN npm ci

COPY visualize/ ./
COPY infra/airflow/data/strava_reporting.duckdb ./sources/strava/strava_reporting.duckdb

ENV EVIDENCE_SOURCE__strava__filename=strava_reporting.duckdb
RUN npx evidence sources && VITE_EVIDENCE_SPA=true npx evidence build && node scripts/patch-splash.js

FROM nginx:alpine

RUN apk add --no-cache openssl

COPY infra/visualize/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/ /usr/share/nginx/html/
COPY infra/visualize/scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
