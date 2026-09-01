# Modeled on apps/OpenSign/Dockerhubfile at v2.38.0 -- the recipe the image
# currently serving sign.crm-playbookexp.com was built from -- so this client
# differs from what is live only by the CRM theme.

FROM node:22.14.0

WORKDIR /usr/src/app

COPY apps/OpenSign/package*.json ./

# --include=dev because the Railway service sets NODE_ENV=production, which
# would otherwise drop vite and every other build-time dependency.
RUN npm ci --include=dev

COPY apps/OpenSign/ .

RUN chmod +x entrypoint.sh

ENV NODE_ENV=production
ENV GENERATE_SOURCEMAP=false

# Upstream's build script curls the GitHub releases API for this stamp. Write
# it directly so a production build never depends on that API being reachable.
RUN printf 'v2.38.0-playbook' > public/version.txt && npx vite build

# index.html already loads /env.js, so upstream's sed injection is not repeated
# here -- entrypoint.sh writes that file from REACT_APP_SERVERURL at start-up.

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]

CMD ["npm", "start"]
