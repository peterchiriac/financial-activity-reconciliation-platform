--
-- PostgreSQL database dump
--

\restrict vaUB3paKrvSbu6OA0jT6bdlb2c9nmpaUxKstKROtphJ9bTRH9IpPVBIcK6123rw

-- Dumped from database version 18.4 (Postgres.app)
-- Dumped by pg_dump version 18.4 (Postgres.app)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: platforms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platforms (
    platform_id integer NOT NULL,
    platform_name character varying(100) NOT NULL,
    platform_type character varying(20) NOT NULL,
    default_commission_rate numeric(5,4) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT platforms_default_commission_rate_check CHECK (((default_commission_rate >= (0)::numeric) AND (default_commission_rate <= (1)::numeric))),
    CONSTRAINT platforms_platform_type_check CHECK (((platform_type)::text = ANY ((ARRAY['BOOKMAKER'::character varying, 'EXCHANGE'::character varying, 'BANK'::character varying, 'WALLET'::character varying])::text[])))
);


--
-- Name: promotions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promotions (
    promotion_id integer NOT NULL,
    platform_id integer NOT NULL,
    promotion_name character varying(150) NOT NULL,
    promo_code character varying(50),
    qualifying_stake numeric(10,2),
    minimum_odds numeric(10,3),
    minimum_selections integer,
    reward_value numeric(10,2),
    reward_type character varying(30),
    promotion_status character varying(30) DEFAULT 'AVAILABLE'::character varying NOT NULL,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT promotions_minimum_odds_check CHECK ((minimum_odds > (1)::numeric)),
    CONSTRAINT promotions_minimum_selections_check CHECK ((minimum_selections >= 1)),
    CONSTRAINT promotions_promotion_status_check CHECK (((promotion_status)::text = ANY ((ARRAY['AVAILABLE'::character varying, 'QUALIFYING_BET_PLACED'::character varying, 'REWARD_CREDITED'::character varying, 'COMPLETED'::character varying, 'EXPIRED'::character varying, 'CANCELLED'::character varying])::text[]))),
    CONSTRAINT promotions_qualifying_stake_check CHECK ((qualifying_stake > (0)::numeric)),
    CONSTRAINT promotions_reward_type_check CHECK (((reward_type)::text = ANY ((ARRAY['FREE_BET'::character varying, 'CASH'::character varying, 'BONUS'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT promotions_reward_value_check CHECK ((reward_value > (0)::numeric))
);


--
-- Name: rewards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rewards (
    reward_id integer NOT NULL,
    promotion_id integer NOT NULL,
    qualifying_bet_id integer,
    reward_type character varying(30) NOT NULL,
    face_value numeric(10,2) NOT NULL,
    reward_status character varying(30) DEFAULT 'EXPECTED'::character varying NOT NULL,
    credited_at timestamp with time zone,
    expires_at timestamp with time zone,
    converted_cash_value numeric(10,2),
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    used_bet_id integer,
    CONSTRAINT rewards_converted_cash_value_check CHECK ((converted_cash_value >= (0)::numeric)),
    CONSTRAINT rewards_face_value_check CHECK ((face_value > (0)::numeric)),
    CONSTRAINT rewards_reward_status_check CHECK (((reward_status)::text = ANY ((ARRAY['EXPECTED'::character varying, 'CREDITED'::character varying, 'USED'::character varying, 'EXPIRED'::character varying, 'REVOKED'::character varying])::text[]))),
    CONSTRAINT rewards_reward_type_check CHECK (((reward_type)::text = ANY ((ARRAY['FREE_BET'::character varying, 'CASH'::character varying, 'BONUS'::character varying, 'OTHER'::character varying])::text[])))
);


--
-- Name: active_promotional_assets; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.active_promotional_assets AS
 SELECT p.platform_id,
    p.platform_name,
    r.reward_type,
    count(*) AS reward_count,
    (sum(r.face_value))::numeric(12,2) AS promotional_face_value,
    min(r.expires_at) AS nearest_expiry
   FROM ((public.rewards r
     JOIN public.promotions pr ON ((pr.promotion_id = r.promotion_id)))
     JOIN public.platforms p ON ((p.platform_id = pr.platform_id)))
  WHERE ((r.reward_status)::text = 'CREDITED'::text)
  GROUP BY p.platform_id, p.platform_name, r.reward_type;


--
-- Name: bet_legs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bet_legs (
    bet_leg_id integer NOT NULL,
    bet_id integer NOT NULL,
    leg_number integer NOT NULL,
    sport character varying(50) NOT NULL,
    competition character varying(150),
    event_name character varying(200) NOT NULL,
    selection_name character varying(150) NOT NULL,
    market_name character varying(100) NOT NULL,
    selection_odds numeric(10,3),
    event_start_at timestamp with time zone,
    leg_status character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    CONSTRAINT bet_legs_leg_number_check CHECK ((leg_number >= 1)),
    CONSTRAINT bet_legs_leg_status_check CHECK (((leg_status)::text = ANY ((ARRAY['OPEN'::character varying, 'WON'::character varying, 'LOST'::character varying, 'VOID'::character varying])::text[]))),
    CONSTRAINT bet_legs_selection_odds_check CHECK ((selection_odds > (1)::numeric))
);


--
-- Name: bet_legs_bet_leg_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.bet_legs ALTER COLUMN bet_leg_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.bet_legs_bet_leg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: bets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bets (
    bet_id integer NOT NULL,
    platform_id integer NOT NULL,
    promotion_id integer,
    related_bet_id integer,
    bet_side character varying(10) NOT NULL,
    bet_type character varying(30) NOT NULL,
    stake numeric(10,2) NOT NULL,
    decimal_odds numeric(10,3) NOT NULL,
    liability numeric(10,2),
    commission_rate numeric(5,4) DEFAULT 0 NOT NULL,
    bet_status character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    cash_return numeric(10,2),
    placed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    settled_at timestamp with time zone,
    notes text,
    related_bet_leg_id integer,
    stake_type character varying(20) DEFAULT 'CASH'::character varying NOT NULL,
    CONSTRAINT bets_bet_side_check CHECK (((bet_side)::text = ANY ((ARRAY['BACK'::character varying, 'LAY'::character varying])::text[]))),
    CONSTRAINT bets_bet_status_check CHECK (((bet_status)::text = ANY ((ARRAY['OPEN'::character varying, 'WON'::character varying, 'LOST'::character varying, 'VOID'::character varying, 'CASHED_OUT'::character varying])::text[]))),
    CONSTRAINT bets_bet_type_check CHECK (((bet_type)::text = ANY ((ARRAY['SINGLE'::character varying, 'ACCUMULATOR'::character varying, 'BET_BUILDER'::character varying])::text[]))),
    CONSTRAINT bets_cash_return_check CHECK ((cash_return >= (0)::numeric)),
    CONSTRAINT bets_check CHECK (((((bet_side)::text = 'BACK'::text) AND (liability IS NULL)) OR (((bet_side)::text = 'LAY'::text) AND (liability IS NOT NULL)))),
    CONSTRAINT bets_commission_rate_check CHECK (((commission_rate >= (0)::numeric) AND (commission_rate <= (1)::numeric))),
    CONSTRAINT bets_decimal_odds_check CHECK ((decimal_odds > (1)::numeric)),
    CONSTRAINT bets_liability_check CHECK ((liability >= (0)::numeric)),
    CONSTRAINT bets_stake_check CHECK ((stake > (0)::numeric)),
    CONSTRAINT bets_stake_type_check CHECK (((stake_type)::text = ANY ((ARRAY['CASH'::character varying, 'FREE_BET'::character varying, 'BONUS_CASH'::character varying])::text[])))
);


--
-- Name: bets_bet_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.bets ALTER COLUMN bet_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.bets_bet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: expected_rewards; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.expected_rewards AS
 SELECT p.platform_id,
    p.platform_name,
    count(*) AS expected_reward_count,
    (sum(r.face_value))::numeric(12,2) AS expected_face_value,
    min(r.expires_at) AS nearest_expiry
   FROM ((public.rewards r
     JOIN public.promotions pr ON ((pr.promotion_id = r.promotion_id)))
     JOIN public.platforms p ON ((p.platform_id = pr.platform_id)))
  WHERE ((r.reward_status)::text = 'EXPECTED'::text)
  GROUP BY p.platform_id, p.platform_name;


--
-- Name: open_bet_exposure; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.open_bet_exposure AS
 SELECT count(*) AS open_bet_count,
    (COALESCE(sum(stake) FILTER (WHERE ((bet_side)::text = 'BACK'::text)), 0.00))::numeric(12,2) AS open_back_stakes,
    (COALESCE(sum(liability) FILTER (WHERE ((bet_side)::text = 'LAY'::text)), 0.00))::numeric(12,2) AS open_lay_liability
   FROM public.bets
  WHERE ((bet_status)::text = 'OPEN'::text);


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    transaction_id integer NOT NULL,
    platform_id integer NOT NULL,
    bet_id integer,
    promotion_id integer,
    reward_id integer,
    transaction_type character varying(30) NOT NULL,
    amount numeric(12,2) NOT NULL,
    external_reference character varying(150),
    transfer_reference character varying(100),
    occurred_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT transactions_amount_check CHECK ((amount <> (0)::numeric)),
    CONSTRAINT transactions_transaction_type_check CHECK (((transaction_type)::text = ANY ((ARRAY['TRANSFER_IN'::character varying, 'TRANSFER_OUT'::character varying, 'DEPOSIT'::character varying, 'WITHDRAWAL'::character varying, 'ADJUSTMENT'::character varying])::text[])))
);


--
-- Name: v_bet_reconciliation; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_bet_reconciliation AS
 SELECT b.bet_id,
    p.platform_name,
    b.bet_side,
    b.bet_type,
    b.stake_type,
    b.stake,
    b.decimal_odds,
    b.liability,
    b.commission_rate,
    b.bet_status,
    b.cash_return,
        CASE
            WHEN ((b.bet_status)::text = 'OPEN'::text) THEN NULL::numeric
            WHEN (((b.bet_side)::text = 'BACK'::text) AND ((b.bet_status)::text = 'WON'::text) AND ((b.stake_type)::text = 'CASH'::text)) THEN (b.cash_return - b.stake)
            WHEN (((b.bet_side)::text = 'BACK'::text) AND ((b.bet_status)::text = 'WON'::text) AND ((b.stake_type)::text = 'FREE_BET'::text)) THEN b.cash_return
            WHEN (((b.bet_side)::text = 'BACK'::text) AND ((b.bet_status)::text = 'LOST'::text) AND ((b.stake_type)::text = 'CASH'::text)) THEN (- b.stake)
            WHEN (((b.bet_side)::text = 'BACK'::text) AND ((b.bet_status)::text = 'LOST'::text) AND ((b.stake_type)::text = 'FREE_BET'::text)) THEN 0.00
            WHEN (((b.bet_side)::text = 'LAY'::text) AND ((b.bet_status)::text = 'WON'::text)) THEN b.cash_return
            WHEN (((b.bet_side)::text = 'LAY'::text) AND ((b.bet_status)::text = 'LOST'::text)) THEN (- b.liability)
            ELSE NULL::numeric
        END AS net_result,
    b.related_bet_id,
    b.related_bet_leg_id,
    b.placed_at,
    b.settled_at,
    b.notes
   FROM (public.bets b
     JOIN public.platforms p ON ((p.platform_id = b.platform_id)));


--
-- Name: v_platform_transaction_flows; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_platform_transaction_flows AS
 SELECT p.platform_id,
    p.platform_name,
    COALESCE(sum(
        CASE
            WHEN (t.amount > (0)::numeric) THEN t.amount
            ELSE (0)::numeric
        END), (0)::numeric) AS money_in,
    COALESCE(sum(
        CASE
            WHEN (t.amount < (0)::numeric) THEN abs(t.amount)
            ELSE (0)::numeric
        END), (0)::numeric) AS money_out,
    COALESCE(sum(t.amount), (0)::numeric) AS net_transaction_flow
   FROM (public.platforms p
     LEFT JOIN public.transactions t ON ((t.platform_id = p.platform_id)))
  GROUP BY p.platform_id, p.platform_name
  ORDER BY p.platform_id;


--
-- Name: platform_cash_balances; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.platform_cash_balances AS
 SELECT p.platform_id,
    p.platform_name,
    p.platform_type,
    ((COALESCE(tf.net_transaction_flow, (0)::numeric) + COALESCE(bp.bet_pnl, (0)::numeric)))::numeric(12,2) AS cash_balance
   FROM ((public.platforms p
     LEFT JOIN public.v_platform_transaction_flows tf ON ((tf.platform_id = p.platform_id)))
     LEFT JOIN ( SELECT v_bet_reconciliation.platform_name,
            sum(v_bet_reconciliation.net_result) AS bet_pnl
           FROM public.v_bet_reconciliation
          WHERE (v_bet_reconciliation.net_result IS NOT NULL)
          GROUP BY v_bet_reconciliation.platform_name) bp ON (((bp.platform_name)::text = (p.platform_name)::text)));


--
-- Name: platform_overview; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.platform_overview AS
 SELECT pcb.platform_id,
    pcb.platform_name,
    pcb.platform_type,
    pcb.cash_balance,
    (COALESCE(promo.promotional_face_value, 0.00))::numeric(12,2) AS promotional_face_value,
    ((pcb.cash_balance + COALESCE(promo.promotional_face_value, 0.00)))::numeric(12,2) AS total_reported_value
   FROM (public.platform_cash_balances pcb
     LEFT JOIN ( SELECT active_promotional_assets.platform_id,
            sum(active_promotional_assets.promotional_face_value) AS promotional_face_value
           FROM public.active_promotional_assets
          GROUP BY active_promotional_assets.platform_id) promo ON ((promo.platform_id = pcb.platform_id)));


--
-- Name: platforms_platform_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.platforms ALTER COLUMN platform_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.platforms_platform_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: promotions_promotion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.promotions ALTER COLUMN promotion_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.promotions_promotion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: rewards_reward_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.rewards ALTER COLUMN reward_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.rewards_reward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.transactions ALTER COLUMN transaction_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.transactions_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_bankroll_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_bankroll_summary AS
 SELECT external.external_capital,
    cash.current_cash,
    exposure.reserved_liabilities,
    cash.current_cash AS total_bankroll,
    ((cash.current_cash - external.external_capital))::numeric(12,2) AS net_profit,
        CASE
            WHEN (external.external_capital = (0)::numeric) THEN NULL::numeric
            ELSE (((cash.current_cash - external.external_capital) / external.external_capital))::numeric(12,4)
        END AS roi
   FROM ((( SELECT (COALESCE(sum(abs(transactions.amount)), (0)::numeric))::numeric(12,2) AS external_capital
           FROM public.transactions
          WHERE ((transactions.platform_id = 5) AND ((transactions.transaction_type)::text = 'TRANSFER_OUT'::text))) external
     CROSS JOIN ( SELECT (COALESCE(sum(platform_cash_balances.cash_balance), (0)::numeric))::numeric(12,2) AS current_cash
           FROM public.platform_cash_balances
          WHERE ((platform_cash_balances.platform_type)::text <> 'BANK'::text)) cash)
     CROSS JOIN ( SELECT (COALESCE(sum(bets.liability), (0)::numeric))::numeric(12,2) AS reserved_liabilities
           FROM public.bets
          WHERE (((bets.bet_side)::text = 'LAY'::text) AND ((bets.bet_status)::text = 'OPEN'::text))) exposure);


--
-- Name: v_bet_lifecycle; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_bet_lifecycle AS
 SELECT b.bet_id,
    p.platform_name,
    pr.promotion_name,
    b.bet_side,
    b.bet_type,
    b.stake,
    b.bet_status,
    b.cash_return,
    string_agg(((((bl.leg_number || '. '::text) || (bl.selection_name)::text) || ' @ '::text) || bl.selection_odds), ' | '::text ORDER BY bl.leg_number) AS legs,
    sum(r.face_value) AS reward_value
   FROM ((((public.bets b
     JOIN public.platforms p ON ((p.platform_id = b.platform_id)))
     LEFT JOIN public.promotions pr ON ((pr.promotion_id = b.promotion_id)))
     LEFT JOIN public.bet_legs bl ON ((bl.bet_id = b.bet_id)))
     LEFT JOIN public.rewards r ON ((r.used_bet_id = b.bet_id)))
  GROUP BY b.bet_id, p.platform_name, pr.promotion_name, b.bet_side, b.bet_type, b.stake, b.bet_status, b.cash_return;


--
-- Name: v_promotion_rewards; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_promotion_rewards AS
 SELECT pr.promotion_id,
    p.platform_name,
    pr.promotion_name,
    pr.promotion_status,
    COALESCE(sum(r.face_value), (0)::numeric) AS reward_value,
    count(r.reward_id) AS reward_count
   FROM ((public.promotions pr
     JOIN public.platforms p ON ((p.platform_id = pr.platform_id)))
     LEFT JOIN public.rewards r ON ((r.promotion_id = pr.promotion_id)))
  GROUP BY pr.promotion_id, p.platform_name, pr.promotion_name, pr.promotion_status;


--
-- Name: bet_legs bet_legs_bet_id_leg_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bet_legs
    ADD CONSTRAINT bet_legs_bet_id_leg_number_key UNIQUE (bet_id, leg_number);


--
-- Name: bet_legs bet_legs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bet_legs
    ADD CONSTRAINT bet_legs_pkey PRIMARY KEY (bet_leg_id);


--
-- Name: bets bets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bets
    ADD CONSTRAINT bets_pkey PRIMARY KEY (bet_id);


--
-- Name: platforms platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platforms
    ADD CONSTRAINT platforms_pkey PRIMARY KEY (platform_id);


--
-- Name: platforms platforms_platform_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platforms
    ADD CONSTRAINT platforms_platform_name_key UNIQUE (platform_name);


--
-- Name: promotions promotions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_pkey PRIMARY KEY (promotion_id);


--
-- Name: rewards rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (reward_id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: idx_bet_legs_bet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bet_legs_bet_id ON public.bet_legs USING btree (bet_id);


--
-- Name: idx_bets_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bets_platform_id ON public.bets USING btree (platform_id);


--
-- Name: idx_bets_promotion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bets_promotion_id ON public.bets USING btree (promotion_id);


--
-- Name: idx_bets_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bets_status ON public.bets USING btree (bet_status);


--
-- Name: idx_promotions_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_promotions_platform_id ON public.promotions USING btree (platform_id);


--
-- Name: idx_rewards_promotion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rewards_promotion_id ON public.rewards USING btree (promotion_id);


--
-- Name: idx_rewards_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rewards_status ON public.rewards USING btree (reward_status);


--
-- Name: idx_transactions_bet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_bet_id ON public.transactions USING btree (bet_id);


--
-- Name: idx_transactions_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_occurred_at ON public.transactions USING btree (occurred_at);


--
-- Name: idx_transactions_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_platform_id ON public.transactions USING btree (platform_id);


--
-- Name: bet_legs bet_legs_bet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bet_legs
    ADD CONSTRAINT bet_legs_bet_id_fkey FOREIGN KEY (bet_id) REFERENCES public.bets(bet_id) ON DELETE CASCADE;


--
-- Name: bets bets_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bets
    ADD CONSTRAINT bets_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES public.platforms(platform_id);


--
-- Name: bets bets_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bets
    ADD CONSTRAINT bets_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES public.promotions(promotion_id);


--
-- Name: bets bets_related_bet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bets
    ADD CONSTRAINT bets_related_bet_id_fkey FOREIGN KEY (related_bet_id) REFERENCES public.bets(bet_id);


--
-- Name: bets fk_bets_related_leg; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bets
    ADD CONSTRAINT fk_bets_related_leg FOREIGN KEY (related_bet_leg_id) REFERENCES public.bet_legs(bet_leg_id);


--
-- Name: promotions promotions_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES public.platforms(platform_id);


--
-- Name: rewards rewards_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES public.promotions(promotion_id);


--
-- Name: rewards rewards_qualifying_bet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_qualifying_bet_id_fkey FOREIGN KEY (qualifying_bet_id) REFERENCES public.bets(bet_id);


--
-- Name: rewards rewards_used_bet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_used_bet_id_fkey FOREIGN KEY (used_bet_id) REFERENCES public.bets(bet_id);


--
-- Name: transactions transactions_bet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_bet_id_fkey FOREIGN KEY (bet_id) REFERENCES public.bets(bet_id);


--
-- Name: transactions transactions_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES public.platforms(platform_id);


--
-- Name: transactions transactions_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES public.promotions(promotion_id);


--
-- Name: transactions transactions_reward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_reward_id_fkey FOREIGN KEY (reward_id) REFERENCES public.rewards(reward_id);


--
-- PostgreSQL database dump complete
--

\unrestrict vaUB3paKrvSbu6OA0jT6bdlb2c9nmpaUxKstKROtphJ9bTRH9IpPVBIcK6123rw

