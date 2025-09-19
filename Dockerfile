# Builder stage: install build deps, clone, install & build
FROM node:lts-alpine AS builder
WORKDIR /app

# Install git + build tools (virtual package so we can remove them later),
# and make pnpm available for the build.
RUN apk add --no-cache --virtual .build-deps git python3 build-base \
  && npm install -g pnpm

# Clone repo and build
ARG NEXT_PUBLIC_URL
ENV NEXT_PUBLIC_URL=${NEXT_PUBLIC_URL}

RUN git clone --depth=1 https://github.com/zyachel/libremdb.git . \
  && pnpm install --frozen-lockfile \
  && pnpm build

# Remove git metadata and build-only packages to keep the builder small.
# (Builder stage will be discarded, but this also avoids copying .git)
RUN rm -rf .git \
  && apk del .build-deps

# Final (runtime) stage: lightweight Alpine Node image
FROM node:lts-alpine AS runner
WORKDIR /app

# Install pnpm in the runtime image (keeps startup command the same)
RUN npm install -g pnpm --no-audit --no-fund

# Copy built app and production node_modules from builder
COPY --from=builder /app /app

EXPOSE 3000
CMD ["pnpm", "start"]
