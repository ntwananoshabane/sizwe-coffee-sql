# Sizwe Coffee FY2025 SQL Analysis

## Project overview
This project analyses the Sizwe Coffee dataset for the FY2025 year-end review. Sizwe Coffee is a coffee roastery and wholesale supplier based in Isando, Johannesburg, with a second distribution centre in Epping, Cape Town. It employs 320 staff and sells to about 1,400 business outlets through Wholesale (70% of revenue, 30/60-day terms) and Subscription (30%, debit-order collection) channels. FY2025 revenue was R480m against R441m in FY2024, while gross margin fell from 34.7% to 33.0%.

The analysis answers eight questions for Nomsa Dlamini (Financial Director) and Bongani Twala (National Sales Manager), covering channel performance, product-line profitability, collections, top accounts, promotional gaps, rep performance, seasonality, and margin decline.

## Dataset
Tables used: `customers`, `products`, `sales_orders`, `sales_lines`, `ar_ledger`, `reps`, and `trade_promotions`.

Key relationships:
- `sales_orders.customer_id` → `customers.customer_id`
- `sales_orders.order_id` → `sales_lines.order_id`
- `sales_lines.sku` → `products.sku`
- `sales_orders.rep_id` and `customers.rep_id` → `reps.rep_id`
- `ar_ledger.customer_id` → `customers.customer_id`
- `trade_promotions.customer_id` → `customers.customer_id`

Revenue is calculated from `sales_lines.line_revenue`, not from `sales_orders`, because an order has no value of its own.

## Skills demonstrated
- **Joins across multiple tables:** Tasks 1–8
- **Conditional aggregation (`CASE WHEN`):** Tasks 1, 3, 8
- **`LEFT JOIN` to avoid dropping unassigned reps/customers:** Tasks 4 and 6
- **`NOT EXISTS` anti-join:** Task 5
- **CTEs and Window functions (`LAG`, `AVG OVER`, `SUM OVER`):** Tasks 7 and 8
- **Date handling in Databricks (`DATE_TRUNC`, `datediff`):** Tasks 3 and 7
- **Portable division (`* 1.0`):** All ratio queries

## How to run
This analysis was built and run in **Databricks SQL**.

1. Upload the nine CSV files to a Unity Catalog Volume. In this environment, the path is `/Volumes/workspace/default/sizwe_data/`.
2. Run the nine `CREATE TABLE ... AS SELECT * FROM read_files(...)` statements to create the tables.
3. Run `DESCRIBE` on the tables to verify column names (e.g., note that `ar_ledger` uses `invoice_amount`, not `amount`, and `sales_lines` uses `cogs`).
4. Open `queries.sql` in a Databricks SQL notebook and run the queries one by one.
5. **Databricks SQL notes:** Use `datediff(settlement_date, due_date)` for date differences (not subtraction). The `DATE_TRUNC`, `LAG`, `SUM/AVG OVER`, `FILTER`, CTEs and `NULLS LAST` syntax all behave identically to PostgreSQL.

## Key insights
- **Channel performance:** Wholesale remains the dominant channel, generating R335.4m versus R308.2m, a growth of 8.85%. Subscription grew at a nearly identical rate (8.84%).
- **Profit concentration:** House Blend earned the highest gross profit at R10.7m. Highest margin was Single Origin at 44.27%.
- **Collections:** Wholesale carried the largest outstanding balance at roughly R878.4m, averaging 17.2 days late against terms. Subscription is settled 26.2 days early on average.
- **Top accounts:** The largest FY2025 customers are led by Halvane Retail Group at R3.8m.
- **Promotion gap:** Umhlanga Fresh 108 is the largest Wholesale customer with no trade promotion, generating R6.2m.
- **Sales targets:** Because the dataset lacked a target column, Kagiso Mkhize was identified as the top revenue driver at R59.9m.
- **Seasonality:** December 2023 was the quietest month at R29.8m, showing a clear holiday dip followed by a strong January/February rebound.
- **Margin decline:** The fall from 34.7% to 33.0% was driven by Bulk Commercial, whose low margin (19.9%) product saw a massive revenue increase from R110m to R161m, diluting the overall company margin.