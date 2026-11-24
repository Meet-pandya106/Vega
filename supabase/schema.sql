-- ==============================================================================
-- PERSONAL F&O TRADING LEDGER & ACCOUNTING SCHEMA (DHAN BROKER SPECIFIC)
-- Target: Supabase (PostgreSQL 15+)
-- Author: Meet Pandya
-- ==============================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. User Profile & Account Settings
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    dhan_client_id TEXT,
    initial_capital NUMERIC(14, 2) DEFAULT 100000.00,
    current_cash_balance NUMERIC(14, 2) DEFAULT 100000.00,
    financial_year_start DATE DEFAULT '2026-04-01',
    biometric_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Capital Ledger (Deposits, Withdrawals, Margin Interest)
CREATE TABLE IF NOT EXISTS capital_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    txn_type TEXT NOT NULL CHECK (txn_type IN ('DEPOSIT', 'WITHDRAWAL', 'MARGIN_INTEREST', 'OTHER_CHARGE')),
    amount NUMERIC(12, 2) NOT NULL,
    date DATE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Trade Positions (Multi-Leg & Single F&O / Stock Options)
CREATE TABLE IF NOT EXISTS trade_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,                  -- E.g. 'NIFTY', 'BANKNIFTY', 'RELIANCE'
    asset_category TEXT NOT NULL CHECK (asset_category IN ('INDEX_FO', 'STOCK_FO')),
    strategy_name TEXT NOT NULL,           -- 'Naked Buy', 'Straddle', 'Bear Spread', etc.
    trade_type TEXT NOT NULL CHECK (trade_type IN ('INTRADAY', 'POSITIONAL')),
    status TEXT NOT NULL CHECK (status IN ('OPEN', 'CLOSED')) DEFAULT 'OPEN',
    is_physical_delivery_risk BOOLEAN DEFAULT FALSE,
    entry_time TIMESTAMPTZ NOT NULL,
    exit_time TIMESTAMPTZ,
    
    -- Financial aggregates
    gross_pnl NUMERIC(12, 2) DEFAULT 0.00,
    total_charges NUMERIC(10, 2) DEFAULT 0.00,
    net_pnl NUMERIC(12, 2) DEFAULT 0.00,
    
    -- Journaling & Psychology
    setup_tags TEXT[] DEFAULT '{}',
    mistake_tags TEXT[] DEFAULT '{}',
    emotions TEXT[] DEFAULT '{}',
    chart_screenshot_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Individual Executed Orders / Contract Legs
CREATE TABLE IF NOT EXISTS trade_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    position_id UUID NOT NULL REFERENCES trade_positions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    instrument_type TEXT NOT NULL CHECK (instrument_type IN ('OPT', 'FUT')),
    option_type TEXT CHECK (option_type IN ('CE', 'PE', 'NONE')),
    strike_price NUMERIC(10, 2),
    expiry_date DATE NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('BUY', 'SELL')),
    quantity INT NOT NULL,                  -- Total Qty = Lots * Lot Size
    price NUMERIC(10, 2) NOT NULL,
    executed_at TIMESTAMPTZ NOT NULL,
    
    -- Dhan Specific Statutory Charges Breakdown
    brokerage NUMERIC(8, 2) DEFAULT 0.00,
    stt NUMERIC(8, 2) DEFAULT 0.00,
    exchange_charges NUMERIC(8, 2) DEFAULT 0.00,
    gst NUMERIC(8, 2) DEFAULT 0.00,
    stamp_duty NUMERIC(8, 2) DEFAULT 0.00,
    sebi_charges NUMERIC(8, 2) DEFAULT 0.00,
    ipft_charges NUMERIC(8, 2) DEFAULT 0.00,
    total_order_charges NUMERIC(8, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Business Expenses Ledger (Deductible under F&O PGBP Business Income)
CREATE TABLE IF NOT EXISTS business_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN (
        'BROKER_CHARGES', 'INTERNET_TELECOM', 'SOFTWARE_DATA_FEES', 
        'DEPRECIATION_HARDWARE', 'COURSES_BOOKS', 'ADVISORY', 'OTHER'
    )),
    amount NUMERIC(10, 2) NOT NULL,
    expense_date DATE NOT NULL,
    invoice_number TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) - ZERO COMPROMISE PRIVACY (ONLY SINGLE USER ACCESS)
-- ==============================================================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE capital_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE trade_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trade_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_profiles_owner_access" ON user_profiles
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "capital_ledger_owner_access" ON capital_ledger
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "trade_positions_owner_access" ON trade_positions
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "trade_orders_owner_access" ON trade_orders
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "business_expenses_owner_access" ON business_expenses
    FOR ALL USING (auth.uid() = user_id);

-- ==============================================================================
-- INDEXES FOR FAST ANALYTICS & CALENDAR QUERYING
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_positions_user_entry ON trade_positions(user_id, entry_time);
CREATE INDEX IF NOT EXISTS idx_positions_status ON trade_positions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_position_id ON trade_orders(position_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON business_expenses(user_id, expense_date);
