use offchain_core::ethers;

use super::instantiate_block_subscriber::DescartesBlockSubscriber;
use crate::error::*;

use block_subscriber::BlockSubscriber;
use middleware_factory::{HttpProviderFactory, WsProviderFactory};
use tx_manager::config::TMConfig;
use tx_manager::{provider::Factory, TransactionManager};

use ethers::core::types::Address;
use snafu::ResultExt;
use std::sync::Arc;

pub type DescartesTxManager = Arc<
    TransactionManager<
        Factory<HttpProviderFactory>,
        BlockSubscriber<WsProviderFactory>,
        String,
    >,
>;

pub async fn instantiate_tx_manager(
<<<<<<< HEAD
    config: &crate::config::DescartesConfig,
) -> Result<(
    BlockSubscriberHandle<<WsProviderFactory as MiddlewareFactory>::Middleware>,
    DescartesBlockSubscriber,
    DescartesTxManager,
    DescartesV2Impl<<HttpProviderFactory as MiddlewareFactory>::Middleware>,
)> {
    let middleware_factory = create_http_factory(config)?;
    let descartesv2_contract = DescartesV2Impl::new(
        config
            .basic_config
            .contracts
            .get("DescartesV2Impl")
            .unwrap()
            .clone(),
        middleware_factory.current().await,
    );
    let factory = Factory::new(
        Arc::clone(&middleware_factory),
        config.tm_config.transaction_timeout,
    );
    let (block_subscriber, handle) = create_block_subscriber(config).await?;
    let transaction_manager = Arc::new(TransactionManager::new(
        factory,
        Arc::clone(&block_subscriber),
        config.tm_config.max_retries,
        config.tm_config.max_delay,
=======
    http_endpoint: String,
    block_subscriber: DescartesBlockSubscriber,
    config: &TMConfig,
) -> Result<DescartesTxManager> {
    let middleware_factory = create_http_factory(http_endpoint)?;
    let factory = Factory::new(
        Arc::clone(&middleware_factory),
        config.transaction_timeout,
    );

    let transaction_manager = Arc::new(TransactionManager::new(
        factory,
        block_subscriber,
        config.max_retries,
        config.max_delay,
>>>>>>> b423880 (Connect rollups logic to state fold server)
    ));

<<<<<<< HEAD
async fn create_ws_factory(
    config: &crate::config::DescartesConfig,
) -> Result<Arc<WsProviderFactory>> {
    WsProviderFactory::new(
        config.basic_config.ws_url.clone().unwrap().clone(),
        config.tm_config.max_retries,
        config.tm_config.max_delay,
    )
    .await
    .context(MiddlewareFactoryError {})
}

fn create_http_factory(
    config: &crate::config::DescartesConfig,
) -> Result<Arc<HttpProviderFactory>> {
    HttpProviderFactory::new(config.basic_config.url.clone())
        .context(MiddlewareFactoryError {})
}

async fn create_block_subscriber(
    config: &crate::config::DescartesConfig,
) -> Result<(
    Arc<BlockSubscriber<WsProviderFactory>>,
    BlockSubscriberHandle<<WsProviderFactory as MiddlewareFactory>::Middleware>,
)> {
    let factory = create_ws_factory(config).await?;
    Ok(BlockSubscriber::create_and_start(
        factory,
        config.bs_config.subscriber_timeout,
        config.bs_config.max_retries,
        config.bs_config.max_delay,
    ))
}
=======
    Ok(transaction_manager)
}

fn create_http_factory(
    http_endpoint: String,
) -> Result<Arc<HttpProviderFactory>> {
    HttpProviderFactory::new(http_endpoint.clone())
        .context(MiddlewareFactoryError {})
}
>>>>>>> b423880 (Connect rollups logic to state fold server)