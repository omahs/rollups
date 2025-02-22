# Copyright Cartesi Pte. Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

# syntax=docker.io/docker/dockerfile:1.4
# deps install
FROM rust:1.70.0-bookworm AS chef

ENV CARGO_REGISTRIES_CARTESI_INDEX=https://github.com/cartesi/crates-index
RUN rustup component add rustfmt
RUN cargo install cargo-chef

# cargo chef prepare stage
FROM chef AS planner

WORKDIR /usr/src/app/offchain
COPY . /usr/src/app
RUN cargo chef prepare --recipe-path recipe.json

# cargo chef cook stage
FROM chef AS builder

RUN <<EOF
DEBIAN_FRONTEND="noninteractive" apt-get update
DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends cmake libprotobuf-dev protobuf-compiler
EOF

WORKDIR /usr/src/app/offchain
COPY --from=planner /usr/src/app/offchain/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

WORKDIR /usr/src/app/offchain
COPY . /usr/src/app

FROM builder as state_server_build
RUN cargo build --release --bin cartesi-rollups-state-server

FROM builder as dispatcher_build
RUN cargo build --release --bin cartesi-rollups-dispatcher

FROM builder as indexer_build
RUN cargo build --release --bin cartesi-rollups-indexer

FROM builder as inspect_server_build
RUN cargo build --release --bin cartesi-rollups-inspect-server

FROM builder as advance_runner_build
RUN PATH="$PATH:$HOME/.local/bin" cargo build --release --bin cartesi-rollups-advance-runner

FROM builder as graphql_server_build
RUN cargo build --release --bin cartesi-rollups-graphql-server

FROM builder as host_runner_build
RUN cargo build --release --bin cartesi-rollups-host-runner

# define runtime image
FROM debian:bookworm-20230612-slim as runtime
RUN addgroup --system --gid 102 cartesi && \
    adduser --system --uid 102 --ingroup cartesi --disabled-login --no-create-home --home /nonexistent --gecos "cartesi user" --shell /bin/false cartesi
RUN mkdir -p /var/opt/cartesi
RUN chown cartesi:cartesi /var/opt/cartesi
WORKDIR /var/opt/cartesi
ENV PATH="/opt/cartesi/bin:${PATH}"

## runtimes
FROM runtime AS state_server
RUN <<EOF
apt-get update
DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends ca-certificates
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=state_server_build /usr/src/app/offchain/target/release/cartesi-rollups-state-server /opt/cartesi/bin/cartesi-rollups-state-server
USER cartesi
ENTRYPOINT ["/opt/cartesi/bin/cartesi-rollups-state-server"]

FROM runtime AS indexer
RUN <<EOF
apt-get update
DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends libpq5 ca-certificates
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=indexer_build /usr/src/app/offchain/target/release/cartesi-rollups-indexer /opt/cartesi/bin/cartesi-rollups-indexer
USER cartesi
ENTRYPOINT ["/opt/cartesi/bin/cartesi-rollups-indexer"]

FROM runtime AS dispatcher
RUN <<EOF
apt-get update
DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends ca-certificates
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=dispatcher_build /usr/src/app/offchain/target/release/cartesi-rollups-dispatcher /opt/cartesi/bin/cartesi-rollups-dispatcher
COPY onchain/rollups/export/abi /opt/cartesi/share/deployments/
USER cartesi
ENTRYPOINT ["/opt/cartesi/bin/cartesi-rollups-dispatcher"]

FROM runtime AS advance_runner
RUN <<EOF
apt-get update
DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends ca-certificates curl
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=advance_runner_build /usr/src/app/offchain/target/release/cartesi-rollups-advance-runner /opt/cartesi/bin/cartesi-rollups-advance-runner
USER cartesi
ENTRYPOINT ["/opt/cartesi/bin/cartesi-rollups-advance-runner"]

FROM runtime AS inspect_server
COPY --from=inspect_server_build /usr/src/app/offchain/target/release/cartesi-rollups-inspect-server /opt/cartesi/bin/cartesi-rollups-inspect-server
USER cartesi
ENTRYPOINT ["/opt/cartesi/bin/cartesi-rollups-inspect-server"]

FROM runtime AS graphql_server
RUN <<EOF
apt-get update
DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends libpq5
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=graphql_server_build /usr/src/app/offchain/target/release/cartesi-rollups-graphql-server /opt/cartesi/bin/cartesi-rollups-graphql-server
USER cartesi
ENTRYPOINT ["/opt/cartesi/bin/cartesi-rollups-graphql-server"]

FROM runtime AS host_runner
COPY --from=host_runner_build /usr/src/app/offchain/target/release/cartesi-rollups-host-runner /opt/cartesi/bin/cartesi-rollups-host-runner
USER cartesi
ENTRYPOINT ["/opt/cartesi/bin/cartesi-rollups-host-runner"]

FROM scratch AS deployments

WORKDIR /opt/cartesi/share/deployments
COPY onchain/rollups/export/abi .
