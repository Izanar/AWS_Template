# Build with the AI_Nginx checkout as the context; audio is delivered by CloudFront.
FROM nginx:1.27.4 AS content
COPY html/ /app/
RUN rm -rf /app/audio

FROM nginx:1.27.4
COPY --from=content /app/ /usr/share/nginx/html/
RUN command -v curl
