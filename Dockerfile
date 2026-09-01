FROM node:22-bookworm-slim AS build

WORKDIR /app

COPY apps/OpenSign/package.json apps/OpenSign/package-lock.json ./
RUN npm ci

COPY apps/OpenSign ./

# Keep the client build deterministic and avoid making the production build
# depend on GitHub's releases API being available.
RUN printf 'v2.38.0-playbook' > public/version.txt && npx vite build

FROM node:22-alpine

WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app/build ./build
COPY --from=build /app/server.cjs ./server.cjs
COPY --from=build /app/entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]
CMD ["node", "server.cjs"]
