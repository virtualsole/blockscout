defmodule RPCTranslatorForwarder do
  @moduledoc """
  Phoenix router limits forwarding,
  so this module is to forward old paths for backward compatibility
  """
  alias BlockScoutWeb.API.RPC.RPCTranslator
  defdelegate init(opts), to: RPCTranslator
  defdelegate call(conn, opts), to: RPCTranslator
end

defmodule BlockScoutWeb.ApiRouter do
  @moduledoc """
  Router for API
  """
  use BlockScoutWeb, :router
  alias BlockScoutWeb.{AddressTransactionController, APIKeyV2Router, SmartContractsApiV2Router}
  alias BlockScoutWeb.Plug.{CheckAccountAPI, CheckApiV2, RateLimit}

  forward("/v2/smart-contracts", SmartContractsApiV2Router)
  forward("/v2/key", APIKeyV2Router)

  pipeline :api do
    plug(BlockScoutWeb.Plug.Logger, application: :api)
    plug(:accepts, ["json"])
  end

  pipeline :account_api do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(CheckAccountAPI)
  end

  pipeline :api_v2 do
    plug(BlockScoutWeb.Plug.Logger, application: :api_v2)
    plug(:accepts, ["json"])
    plug(CheckApiV2)
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(RateLimit)
  end

  pipeline :api_v2_no_session do
    plug(BlockScoutWeb.Plug.Logger, application: :api_v2)
    plug(:accepts, ["json"])
    plug(CheckApiV2)
    plug(RateLimit)
  end

  alias BlockScoutWeb.Account.Api.V1.{AuthenticateController, EmailController, TagsController, UserController}
  alias BlockScoutWeb.API.V2

  # TODO: Remove /account/v1 paths
  scope "/account/v1", as: :account_v1 do
    pipe_through(:api)
    pipe_through(:account_api)

    get("/authenticate", AuthenticateController, :authenticate_get)
    post("/authenticate", AuthenticateController, :authenticate_post)

    get("/get_csrf", UserController, :get_csrf)

    scope "/email" do
      get("/resend", EmailController, :resend_email)
    end

    scope "/user" do
      get("/info", UserController, :info)

      get("/watchlist", UserController, :watchlist_old)
      delete("/watchlist/:id", UserController, :delete_watchlist)
      post("/watchlist", UserController, :create_watchlist)
      put("/watchlist/:id", UserController, :update_watchlist)

      get("/api_keys", UserController, :api_keys)
      delete("/api_keys/:api_key", UserController, :delete_api_key)
      post("/api_keys", UserController, :create_api_key)
      put("/api_keys/:api_key", UserController, :update_api_key)

      get("/custom_abis", UserController, :custom_abis)
      delete("/custom_abis/:id", UserController, :delete_custom_abi)
      post("/custom_abis", UserController, :create_custom_abi)
      put("/custom_abis/:id", UserController, :update_custom_abi)

      get("/public_tags", UserController, :public_tags_requests)
      delete("/public_tags/:id", UserController, :delete_public_tags_request)
      post("/public_tags", UserController, :create_public_tags_request)
      put("/public_tags/:id", UserController, :update_public_tags_request)

      scope "/tags" do
        get("/address/", UserController, :tags_address_old)
        get("/address/:id", UserController, :tags_address)
        delete("/address/:id", UserController, :delete_tag_address)
        post("/address/", UserController, :create_tag_address)
        put("/address/:id", UserController, :update_tag_address)

        get("/transaction/", UserController, :tags_transaction_old)
        get("/transaction/:id", UserController, :tags_transaction)
        delete("/transaction/:id", UserController, :delete_tag_transaction)
        post("/transaction/", UserController, :create_tag_transaction)
        put("/transaction/:id", UserController, :update_tag_transaction)
      end
    end
  end

  # TODO: Remove /account/v1 paths
  scope "/account/v1" do
    pipe_through(:api)
    pipe_through(:account_api)

    scope "/tags" do
      get("/address/:address_hash", TagsController, :tags_address)

      get("/transaction/:transaction_hash", TagsController, :tags_transaction)
    end
  end

  scope "/account/v2", as: :account_v2 do
    pipe_through(:api)
    pipe_through(:account_api)

    get("/authenticate", AuthenticateController, :authenticate_get)
    post("/authenticate", AuthenticateController, :authenticate_post)

    get("/get_csrf", UserController, :get_csrf)

    scope "/email" do
      get("/resend", EmailController, :resend_email)
    end

    scope "/user" do
      get("/info", UserController, :info)

      get("/watchlist", UserController, :watchlist)
      delete("/watchlist/:id", UserController, :delete_watchlist)
      post("/watchlist", UserController, :create_watchlist)
      put("/watchlist/:id", UserController, :update_watchlist)

      get("/api_keys", UserController, :api_keys)
      delete("/api_keys/:api_key", UserController, :delete_api_key)
      post("/api_keys", UserController, :create_api_key)
      put("/api_keys/:api_key", UserController, :update_api_key)

      get("/custom_abis", UserController, :custom_abis)
      delete("/custom_abis/:id", UserController, :delete_custom_abi)
      post("/custom_abis", UserController, :create_custom_abi)
      put("/custom_abis/:id", UserController, :update_custom_abi)

      get("/public_tags", UserController, :public_tags_requests)
      delete("/public_tags/:id", UserController, :delete_public_tags_request)
      post("/public_tags", UserController, :create_public_tags_request)
      put("/public_tags/:id", UserController, :update_public_tags_request)

      scope "/tags" do
        get("/address/", UserController, :tags_address)
        get("/address/:id", UserController, :tags_address)
        delete("/address/:id", UserController, :delete_tag_address)
        post("/address/", UserController, :create_tag_address)
        put("/address/:id", UserController, :update_tag_address)

        get("/transaction/", UserController, :tags_transaction)
        get("/transaction/:id", UserController, :tags_transaction)
        delete("/transaction/:id", UserController, :delete_tag_transaction)
        post("/transaction/", UserController, :create_tag_transaction)
        put("/transaction/:id", UserController, :update_tag_transaction)
      end
    end
  end

  scope "/account/v2" do
    pipe_through(:api)
    pipe_through(:account_api)

    scope "/tags" do
      get("/address/:address_hash", TagsController, :tags_address)

      get("/transaction/:transaction_hash", TagsController, :tags_transaction)
    end
  end

  scope "/v2/import" do
    pipe_through(:api_v2_no_session)

    post("/token-info", V2.ImportController, :import_token_info)
    get("/smart-contracts/:address_hash_param", V2.ImportController, :try_to_search_contract)
  end

  scope "/v2", as: :api_v2 do
    pipe_through(:api_v2)

    scope "/search" do
      get("/", V2.SearchController, :search)
      get("/check-redirect", V2.SearchController, :check_redirect)
      get("/quick", V2.SearchController, :quick_search)
    end

    scope "/config" do
      get("/json-rpc-url", V2.ConfigController, :json_rpc_url)
      get("/backend-version", V2.ConfigController, :backend_version)
    end

    scope "/transactions" do
      get("/", V2.TransactionController, :transactions)
      get("/watchlist", V2.TransactionController, :watchlist_transactions)

      if System.get_env("CHAIN_TYPE") == "polygon_zkevm" do
        get("/zkevm-batch/:batch_number", V2.TransactionController, :zkevm_batch)
      end

      if System.get_env("CHAIN_TYPE") == "suave" do
        get("/execution-node/:execution_node_hash_param", V2.TransactionController, :execution_node)
      end

      get("/:transaction_hash_param", V2.TransactionController, :transaction)
      get("/:transaction_hash_param/token-transfers", V2.TransactionController, :token_transfers)
      get("/:transaction_hash_param/internal-transactions", V2.TransactionController, :internal_transactions)
      get("/:transaction_hash_param/logs", V2.TransactionController, :logs)
      get("/:transaction_hash_param/raw-trace", V2.TransactionController, :raw_trace)
      get("/:transaction_hash_param/state-changes", V2.TransactionController, :state_changes)
      get("/:transaction_hash_param/summary", V2.TransactionController, :summary)
    end

    scope "/blocks" do
      get("/", V2.BlockController, :blocks)
      get("/:block_hash_or_number", V2.BlockController, :block)
      get("/:block_hash_or_number/transactions", V2.BlockController, :transactions)
      get("/:block_hash_or_number/withdrawals", V2.BlockController, :withdrawals)
    end

    scope "/addresses" do
      get("/", V2.AddressController, :addresses_list)
      get("/:address_hash_param", V2.AddressController, :address)
      get("/:address_hash_param/tabs-counters", V2.AddressController, :tabs_counters)
      get("/:address_hash_param/counters", V2.AddressController, :counters)
      get("/:address_hash_param/token-balances", V2.AddressController, :token_balances)
      get("/:address_hash_param/tokens", V2.AddressController, :tokens)
      get("/:address_hash_param/transactions", V2.AddressController, :transactions)
      get("/:address_hash_param/token-transfers", V2.AddressController, :token_transfers)
      get("/:address_hash_param/internal-transactions", V2.AddressController, :internal_transactions)
      get("/:address_hash_param/logs", V2.AddressController, :logs)
      get("/:address_hash_param/blocks-validated", V2.AddressController, :blocks_validated)
      get("/:address_hash_param/coin-balance-history", V2.AddressController, :coin_balance_history)
      get("/:address_hash_param/coin-balance-history-by-day", V2.AddressController, :coin_balance_history_by_day)
      get("/:address_hash_param/withdrawals", V2.AddressController, :withdrawals)
      get("/:address_hash_param/nft", V2.AddressController, :nft_list)
      get("/:address_hash_param/nft/collections", V2.AddressController, :nft_collections)
    end

    scope "/tokens" do
      get("/", V2.TokenController, :tokens_list)
      get("/:address_hash_param", V2.TokenController, :token)
      get("/:address_hash_param/counters", V2.TokenController, :counters)
      get("/:address_hash_param/transfers", V2.TokenController, :transfers)
      get("/:address_hash_param/holders", V2.TokenController, :holders)
      get("/:address_hash_param/instances", V2.TokenController, :instances)
      get("/:address_hash_param/instances/:token_id", V2.TokenController, :instance)
      get("/:address_hash_param/instances/:token_id/transfers", V2.TokenController, :transfers_by_instance)
      get("/:address_hash_param/instances/:token_id/holders", V2.TokenController, :holders_by_instance)
      get("/:address_hash_param/instances/:token_id/transfers-count", V2.TokenController, :transfers_count_by_instance)
    end

    scope "/main-page" do
      get("/blocks", V2.MainPageController, :blocks)
      get("/transactions", V2.MainPageController, :transactions)
      get("/transactions/watchlist", V2.MainPageController, :watchlist_transactions)
      get("/indexing-status", V2.MainPageController, :indexing_status)

      if System.get_env("CHAIN_TYPE") == "polygon_zkevm" do
        get("/zkevm/batches/confirmed", V2.ZkevmController, :batches_confirmed)
        get("/zkevm/batches/latest-number", V2.ZkevmController, :batch_latest_number)
      end
    end

    scope "/stats" do
      get("/", V2.StatsController, :stats)

      scope "/charts" do
        get("/transactions", V2.StatsController, :transactions_chart)
        get("/market", V2.StatsController, :market_chart)
      end
    end

    scope "/polygon-edge" do
      if System.get_env("CHAIN_TYPE") == "polygon_edge" do
        get("/deposits", V2.PolygonEdgeController, :deposits)
        get("/deposits/count", V2.PolygonEdgeController, :deposits_count)
        get("/withdrawals", V2.PolygonEdgeController, :withdrawals)
        get("/withdrawals/count", V2.PolygonEdgeController, :withdrawals_count)
      end
    end

    scope "/withdrawals" do
      get("/", V2.WithdrawalController, :withdrawals_list)
      get("/counters", V2.WithdrawalController, :withdrawals_counters)
    end

    scope "/zkevm" do
      if System.get_env("CHAIN_TYPE") == "polygon_zkevm" do
        get("/batches", V2.ZkevmController, :batches)
        get("/batches/count", V2.ZkevmController, :batches_count)
        get("/batches/:batch_number", V2.ZkevmController, :batch)
      end
    end

    scope "/proxy" do
      scope "/noves-fi" do
        get("/transactions/:transaction_hash_param", V2.Proxy.NovesFiController, :transaction)
        get("/transactions/:transaction_hash_param/describe", V2.Proxy.NovesFiController, :describe_transaction)
        get("/addresses/:address_hash_param/transactions", V2.Proxy.NovesFiController, :address_transactions)
      end

      scope "/account-abstraction" do
        get("/operations/:operation_hash_param", V2.Proxy.AccountAbstractionController, :operation)
        get("/bundlers/:address_hash_param", V2.Proxy.AccountAbstractionController, :bundler)
        get("/bundlers", V2.Proxy.AccountAbstractionController, :bundlers)
        get("/factories/:address_hash_param", V2.Proxy.AccountAbstractionController, :factory)
        get("/factories", V2.Proxy.AccountAbstractionController, :factories)
        get("/paymasters/:address_hash_param", V2.Proxy.AccountAbstractionController, :paymaster)
        get("/paymasters", V2.Proxy.AccountAbstractionController, :paymasters)
        get("/accounts/:address_hash_param", V2.Proxy.AccountAbstractionController, :account)
        get("/accounts", V2.Proxy.AccountAbstractionController, :accounts)
        get("/bundles", V2.Proxy.AccountAbstractionController, :bundles)
        get("/operations", V2.Proxy.AccountAbstractionController, :operations)
      end
    end
  end

  scope "/v1", as: :api_v1 do
    pipe_through(:api)
    alias BlockScoutWeb.API.{EthRPC, RPC, V1}
    alias BlockScoutWeb.API.V1.{GasPriceOracleController, HealthController}
    alias BlockScoutWeb.API.V2.SearchController

    # leave the same endpoint in v1 in order to keep backward compatibility
    get("/search", SearchController, :search)

    @max_complexity 200

    forward("/graphql", Absinthe.Plug,
      schema: BlockScoutWeb.Schema,
      analyze_complexity: true,
      max_complexity: @max_complexity
    )

    get("/transactions-csv", AddressTransactionController, :transactions_csv)

    get("/token-transfers-csv", AddressTransactionController, :token_transfers_csv)

    get("/internal-transactions-csv", AddressTransactionController, :internal_transactions_csv)

    get("/logs-csv", AddressTransactionController, :logs_csv)

    scope "/health" do
      get("/", HealthController, :health)
      get("/liveness", HealthController, :liveness)
      get("/readiness", HealthController, :readiness)
    end

    get("/gas-price-oracle", GasPriceOracleController, :gas_price_oracle)

    if Application.compile_env(:block_scout_web, __MODULE__)[:reading_enabled] do
      get("/supply", V1.SupplyController, :supply)
      post("/eth-rpc", EthRPC.EthController, :eth_request)
    end

    if Application.compile_env(:block_scout_web, __MODULE__)[:writing_enabled] do
      post("/decompiled_smart_contract", V1.DecompiledSmartContractController, :create)
      post("/verified_smart_contracts", V1.VerifiedSmartContractController, :create)
    end

    if Application.compile_env(:block_scout_web, __MODULE__)[:reading_enabled] do
      forward("/", RPC.RPCTranslator, %{
        "block" => {RPC.BlockController, []},
        "account" => {RPC.AddressController, []},
        "logs" => {RPC.LogsController, []},
        "token" => {RPC.TokenController, []},
        "stats" => {RPC.StatsController, []},
        "contract" => {RPC.ContractController, [:verify]},
        "transaction" => {RPC.TransactionController, []}
      })
    end
  end

  # For backward compatibility. Should be removed
  scope "/" do
    pipe_through(:api)
    alias BlockScoutWeb.API.{EthRPC, RPC}

    if Application.compile_env(:block_scout_web, __MODULE__)[:reading_enabled] do
      post("/eth-rpc", EthRPC.EthController, :eth_request)

      forward("/", RPCTranslatorForwarder, %{
        "block" => {RPC.BlockController, []},
        "account" => {RPC.AddressController, []},
        "logs" => {RPC.LogsController, []},
        "token" => {RPC.TokenController, []},
        "stats" => {RPC.StatsController, []},
        "contract" => {RPC.ContractController, [:verify]},
        "transaction" => {RPC.TransactionController, []}
      })
    end
  end
end
