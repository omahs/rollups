// Copyright Cartesi Pte. Ltd.
//
// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

use axum::http::uri::InvalidUri;
use snafu::Snafu;
use state_client_lib::error::StateServerError;
use std::net::AddrParseError;
use tonic::transport::Error as TonicError;

use crate::{machine, sender};

#[derive(Debug, Snafu)]
#[snafu(visibility(pub(crate)))]
pub enum DispatcherError {
    #[snafu(display("http server error"))]
    HttpServerError { source: hyper::Error },

    #[snafu(display("metrics address error"))]
    MetricsAddressError { source: AddrParseError },

    #[snafu(display("broker facade error"))]
    BrokerError {
        source: machine::rollups_broker::BrokerFacadeError,
    },

    #[snafu(display("connection error"))]
    ChannelError { source: InvalidUri },

    #[snafu(display("connection error"))]
    ConnectError { source: TonicError },

    #[snafu(display("state server error"))]
    StateServerError { source: StateServerError },

    #[snafu(display("sender error"))]
    SenderError { source: sender::SenderError },

    #[snafu(whatever, display("{message}"))]
    Whatever {
        message: String,
        #[snafu(source(from(Box<dyn std::error::Error>, Some)))]
        source: Option<Box<dyn std::error::Error>>,
    },
}
