-- Task 1: Channel performance
SELECT
    so.channel,
    SUM(CASE WHEN so.order_date <= '2024-06-30' THEN sl.line_revenue ELSE 0 END) AS fy2024_revenue,
    SUM(CASE WHEN so.order_date > '2024-06-30' AND so.order_date <= '2025-06-30' THEN sl.line_revenue ELSE 0 END) AS fy2025_revenue,
    ROUND(
        (SUM(CASE WHEN so.order_date > '2024-06-30' AND so.order_date <= '2025-06-30' THEN sl.line_revenue ELSE 0 END) 
         - SUM(CASE WHEN so.order_date <= '2024-06-30' THEN sl.line_revenue ELSE 0 END)) * 1.0
        / NULLIF(SUM(CASE WHEN so.order_date <= '2024-06-30' THEN sl.line_revenue ELSE 0 END), 0) * 100, 2) AS growth_pct
FROM sales_orders so
JOIN sales_lines sl ON sl.order_id = so.order_id
GROUP BY so.channel;

-- Answer: Wholesale remains the dominant channel, generating R335,426,325 in FY2025 compared to R308,166,012 in FY2024, representing a growth of 8.85%. The Subscription channel generated R144,573,698 in FY2025 compared to R132,833,985 in FY2024, growing by 8.84%. Both channels grew at nearly identical rates, meaning the channel split remained relatively stable year-over-year.


-- Task 2: Where the profit actually comes from
SELECT
    p.product_line,
    SUM(sl.line_revenue) AS revenue,
    SUM(sl.cogs) AS cost_of_goods,
    SUM(sl.line_revenue) - SUM(sl.cogs) AS gross_profit,
    ROUND((SUM(sl.line_revenue) - SUM(sl.cogs)) * 1.0 / NULLIF(SUM(sl.line_revenue), 0) * 100, 2) AS gross_margin_pct
FROM sales_lines sl
JOIN products p ON p.sku = sl.sku
GROUP BY p.product_line
ORDER BY gross_profit DESC;

-- Answer: House Blend is the highest driver of gross profit, generating R10,714,874 with a strong margin of 38.33%. Single Origin has the highest gross margin percentage at 44.27% (R7,531,280 profit). However, Bulk Commercial generates almost as much revenue as House Blend (R27.1m) but has a significantly lower margin of only 19.9%. Capsules and Decaf contribute smaller amounts to the bottom line but maintain healthy margins (38.91% and 35.83% respectively).


-- Task 3: The collections problem
SELECT
    c.channel,
    COUNT(*) AS invoice_count,
    COUNT(*) FILTER (WHERE al.amount_settled >= al.invoice_amount) AS settled_invoices,
    COUNT(*) FILTER (WHERE al.amount_settled < al.invoice_amount OR al.amount_settled IS NULL) AS open_invoices,
    ROUND(AVG(CASE WHEN al.settlement_date IS NOT NULL THEN datediff(al.settlement_date, al.due_date) END) * 1.0, 1) AS avg_days_to_settle,
    SUM(CASE WHEN al.amount_settled < al.invoice_amount OR al.amount_settled IS NULL 
             THEN GREATEST(al.invoice_amount - COALESCE(al.amount_settled, 0), 0) ELSE 0 END) AS total_outstanding
FROM ar_ledger al
JOIN customers c ON c.customer_id = al.customer_id
GROUP BY c.channel
ORDER BY total_outstanding DESC;

-- Answer: Wholesale is responsible for the vast majority of the collections problem. It carries a massive outstanding balance of roughly R878.4 million across 3,454 open invoices, and on average, wholesale invoices are settled 17.2 days late. In stark contrast, the Subscription channel has almost no collection issues, with only 44 open invoices and an outstanding balance of roughly R751,000. Subscription invoices are actually settled 26.2 days before the due date on average (likely due to automated debit orders).


-- Task 4: The ten accounts that matter most
SELECT
    c.trading_name,
    c.segment,
    c.province,
    COALESCE(r.rep_name, 'Unassigned') AS sales_representative,
    SUM(sl.line_revenue) AS fy2025_revenue
FROM customers c
JOIN sales_orders so ON so.customer_id = c.customer_id
JOIN sales_lines sl ON sl.order_id = so.order_id
LEFT JOIN reps r ON r.rep_id = c.rep_id
WHERE so.order_date > '2024-06-30' AND so.order_date <= '2025-06-30'
GROUP BY c.customer_id, c.trading_name, c.segment, c.province, r.rep_name
ORDER BY fy2025_revenue DESC
LIMIT 10;

-- Answer: The largest FY2025 account is Halvane Retail Group (a Grocery Chain in the Western Cape) generating R3,839,999.89, looked after by Kagiso Mkhize. The top 10 is heavily dominated by Independent Cafes (4 out of 10), followed by Restaurant and Hotel Groups. The revenue for the top 10 is relatively closely bunched, ranging from R3.8 million down to roughly R1.9 million for the 10th spot. Sales reps Chantal Ismail and Karabo Zwane each manage two of the top 10 accounts.


-- Task 5: A commercial gap
SELECT
    c.trading_name AS customer_name,
    c.segment,
    c.province,
    SUM(sl.line_revenue) AS revenue
FROM customers c
JOIN sales_orders so ON so.customer_id = c.customer_id
JOIN sales_lines sl ON sl.order_id = so.order_id
WHERE c.channel = 'Wholesale'
  AND NOT EXISTS (SELECT 1 FROM trade_promotions tp WHERE tp.customer_id = c.customer_id)
GROUP BY c.customer_id, c.trading_name, c.segment, c.province
ORDER BY revenue DESC
LIMIT 15;

-- Answer: The largest Wholesale customer with no trade promotion is Umhlanga Fresh 108 (a Restaurant Group in Gauteng), which generated R6,224,772.37. The list of unpromoted Wholesale accounts is heavily concentrated in the Independent Cafe and Restaurant Group segments. The top 15 accounts on this list each generated over R2.3 million in revenue, suggesting there is significant commercial opportunity to lock these high-volume accounts into formal trade promotions.


-- Task 6: Are the sales representatives hitting target?
SELECT
    r.rep_name AS sales_representative,
    r.territory,
    ROUND(COALESCE(SUM(sl.line_revenue), 0) / 12.0, 2) AS fy2025_monthly_avg,
    SUM(sl.line_revenue) AS total_fy2025_revenue
FROM reps r
LEFT JOIN sales_orders so ON so.rep_id = r.rep_id AND so.order_date > '2024-06-30' AND so.order_date <= '2025-06-30'
LEFT JOIN sales_lines sl ON sl.order_id = so.order_id
GROUP BY r.rep_id, r.rep_name, r.territory
ORDER BY total_fy2025_revenue DESC;

-- Answer: Because the dataset did not include a "monthly_target" column, we evaluated performance based on total FY2025 revenue. Kagiso Mkhize was the clear top performer, generating R59,955,907.98 in FY2025 (averaging R4,996,325.67 per month) in the Gauteng North territory. Karabo Zwane (Western Cape) and Nomsa Botha (Gauteng South) were the next highest contributors, generating R30.1 million and R28.5 million respectively.


-- Task 7: The shape of the year
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', so.order_date) AS month_start,
        SUM(sl.line_revenue) AS revenue
    FROM sales_orders so
    JOIN sales_lines sl ON sl.order_id = so.order_id
    GROUP BY DATE_TRUNC('month', so.order_date)
)
SELECT
    month_start,
    revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month_start)) * 1.0 / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0) * 100, 2) AS mom_pct_change,
    ROUND(AVG(revenue) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3m_avg
FROM monthly
ORDER BY month_start;

-- Answer: There is a clear seasonal pattern in the business. The quietest month is December 2023, generating roughly R29.8 million. We see a recurring trend where revenue drops significantly in December (a 13.09% drop in Dec 2023 and a 12.89% drop in Dec 2024), likely due to the holiday period. This is consistently followed by a strong rebound in January and February. The rolling 3-month average shows steady overall growth across the two years, culminating in the highest revenue month in June 2025 (R45.1 million).


-- Task 8: Why has the margin moved?
WITH line_fy AS (
    SELECT
        p.product_line,
        CASE WHEN so.order_date <= '2024-06-30' THEN 'FY2024' ELSE 'FY2025' END AS fy,
        SUM(sl.line_revenue) AS revenue,
        SUM(sl.cogs) AS cogs
    FROM sales_orders so
    JOIN sales_lines sl ON sl.order_id = so.order_id
    JOIN products p ON p.sku = sl.sku
    GROUP BY p.product_line, CASE WHEN so.order_date <= '2024-06-30' THEN 'FY2024' ELSE 'FY2025' END
),
with_share AS (
    SELECT
        product_line, fy, revenue, cogs,
        ROUND((revenue - cogs) * 1.0 / NULLIF(revenue, 0) * 100, 2) AS gm_pct,
        ROUND(revenue * 1.0 / SUM(revenue) OVER (PARTITION BY fy) * 100, 2) AS revenue_share_pct
    FROM line_fy
)
SELECT
    product_line,
    MAX(CASE WHEN fy = 'FY2024' THEN revenue END) AS fy2024_revenue,
    MAX(CASE WHEN fy = 'FY2024' THEN gm_pct END) AS fy2024_gm_pct,
    MAX(CASE WHEN fy = 'FY2024' THEN revenue_share_pct END) AS fy2024_share_pct,
    MAX(CASE WHEN fy = 'FY2025' THEN revenue END) AS fy2025_revenue,
    MAX(CASE WHEN fy = 'FY2025' THEN gm_pct END) AS fy2025_gm_pct,
    MAX(CASE WHEN fy = 'FY2025' THEN revenue_share_pct END) AS fy2025_share_pct
FROM with_share
GROUP BY product_line
ORDER BY fy2025_revenue DESC NULLS LAST;

-- Answer: The decline in gross margin from 34.7% to 33.0% was driven by a shift in product mix. Bulk Commercial (which has the lowest gross margin at just 19.9%) saw a massive revenue increase from R110.3 million in FY2024 to R161.5 million in FY2025. Meanwhile, higher-margin products like Single Origin (44.27% margin) and Capsules (38.91% margin) actually saw their revenues decrease year-over-year. Selling a significantly higher proportion of low-margin bulk coffee diluted the company's overall profitability.