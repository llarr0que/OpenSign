FROM node:22-bookworm-slim AS build

WORKDIR /app

COPY apps/OpenSign/package.json apps/OpenSign/package-lock.json ./
RUN npm ci

COPY apps/OpenSign ./

# Keep the client build deterministic and avoid making the production build
# depend on GitHub's releases API being available.
RUN printf 'v2.41.3-playbook' > public/version.txt && npx vite build

FROM node:22-alpine

WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app/build ./build
COPY --from=build /app/server.cjs ./server.cjs

EXPOSE 3000

CMD ["node", "server.cjs"]
