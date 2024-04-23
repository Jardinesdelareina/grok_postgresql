CREATE INDEX idx_portfolios_user ON ms.portfolios(fk_user_id);
CREATE INDEX idx_transactions_portfolio ON ms.transactions(fk_portfolio_id);
CREATE INDEX idx_transactions_currency ON ms.transactions(fk_currency_id);