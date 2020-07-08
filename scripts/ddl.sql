CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

CREATE TABLE IF NOT EXISTS public.exchanges (
  code text COLLATE pg_catalog. "default" NOT NULL,
  name text COLLATE pg_catalog. "default" NOT NULL,
  readable_code text COLLATE pg_catalog. "default",
  CONSTRAINT exchanges_pkey PRIMARY KEY (code))
TABLESPACE pg_default;

ALTER TABLE public.exchanges OWNER TO postgres;

INSERT INTO exchanges (code, readable_code, name)
  VALUES ('N', 'NYSE', 'New York Stock Exchange'), ('A', 'NYSE_MKT', 'NYSE American'), ('P', 'NYSE_ARCA', 'NYSE ARCA'), ('Z', 'BATS', 'BATS Global Markets'), ('V', 'IEXG', 'Investors'' Exchange, LLC'), ('Q', 'NASDAQ', 'Nasdaq');

CREATE TABLE IF NOT EXISTS public.financial_statuses (
  code "char" NOT NULL,
  description text COLLATE pg_catalog. "default" NOT NULL,
  CONSTRAINT financial_statuses_pkey PRIMARY KEY (code))
TABLESPACE pg_default;

ALTER TABLE public.financial_statuses OWNER TO postgres;

INSERT INTO financial_statuses (code, description)
  VALUES ('D', 'Deficient: Issuer Failed to Meet NASDAQ Continued Listing Requirements'), ('E', 'Delinquent: Issuer Missed Regulatory Filing Deadline'), ('Q', 'Bankrupt: Issuer Has Filed for Bankruptcy'), ('N', 'Normal (Default): Issuer Is NOT Deficient, Delinquent, or Bankrupt.'), ('G', 'Deficient and Bankrupt'), ('H', 'Deficient and Delinquent'), ('J', 'Delinquent and Bankrupt'), ('K', 'Deficient, Delinquent, and Bankrupt');

CREATE TABLE IF NOT EXISTS public.tickers (
  symbol text COLLATE pg_catalog. "default" NOT NULL,
  name text COLLATE pg_catalog. "default",
  is_etf boolean,
  is_sap_500 boolean,
  exchange "char" NOT NULL,
  market_category "char",
  round_lot_size integer NOT NULL,
  is_test_issue boolean,
  financial_status "char",
  cqs_symbol text COLLATE pg_catalog. "default",
  nasdaq_symbol text COLLATE pg_catalog. "default",
  next_shares text COLLATE pg_catalog. "default",
  has_data boolean,
  CONSTRAINT symbols_pkey PRIMARY KEY (symbol),
  CONSTRAINT "FK_exchanges" FOREIGN KEY (exchange) REFERENCES public.exchanges (code) MATCH SIMPLE ON UPDATE RESTRICT ON DELETE RESTRICT)
TABLESPACE pg_default;

ALTER TABLE public.tickers OWNER TO postgres;

CREATE TABLE IF NOT EXISTS public.ticker_prices (
  date date NOT NULL,
  symbol text COLLATE pg_catalog. "default" NOT NULL,
  close_adjusted real,
  open real,
  volume bigint,
  dividend_amount real,
  split_coefficient real,
  high real,
  low real,
  close real,
  close_adjusted_cpi real,
  close_adjusted_in_gold real,
  data_source text,
  CONSTRAINT date_ticker UNIQUE (symbol, date))
TABLESPACE pg_default;

ALTER TABLE public.ticker_prices OWNER TO postgres;

SELECT
  create_hypertable ('ticker_prices', 'date', 'symbol', 1, chunk_time_interval => interval '2 year');

CREATE TABLE IF NOT EXISTS public.finra_securities (
  symbol text COLLATE pg_catalog. "default" NOT NULL,
  name text COLLATE pg_catalog. "default" NOT NULL,
  exchange text COLLATE pg_catalog. "default",
  date_removed date,
  CONSTRAINT finra_securities_pkey PRIMARY KEY (symbol))
TABLESPACE pg_default;

ALTER TABLE public.finra_securities OWNER TO postgres;

CREATE TABLE IF NOT EXISTS public.cpi (
  date date NOT NULL,
  cpi real NOT NULL,
  CONSTRAINT cpi_pkey PRIMARY KEY (date))
TABLESPACE pg_default;

ALTER TABLE public.cpi OWNER TO postgres;

CREATE TABLE public.gold_price (
  year integer NOT NULL,
  month integer NOT NULL,
  day integer NOT NULL,
  price_usd real,
  price_gbp real,
  price_eur real,
  CONSTRAINT gold_price_pkey PRIMARY KEY (year, month, day))
TABLESPACE pg_default;

ALTER TABLE public.gold_price OWNER TO postgres;

