# Techniques to optimize your Turso billing quota

This repository contains some examples for reducing the [billed usage] of a
[Turso] database (in terms of rows read) for certain types queries that might
normally require an expensive full table scan. The techniques here also improve
the overall performance of the query as performed by the underlying SQLite query
engine.

Read the [companion blog post] that discusses the reasoning behind these
optimizations.

The examples here boil down to two strategies:

- [Use an index] on fields used with filtering, ordering, `min`, or `max`
- Use [SQLite triggers] to pre-compute aggregate values, such as `sum` and `avg`

The SQL scripts here are designed to be fed directly into the [Turso CLI] or
[sqlite3 CLI] for execution. For example, to create the example table and it
starting data:

```sh
turso db shell $DBNAME < 01_table_and_data.sql
```

## SQL scripts in this repo

### Initial table and data

SQL: [01_table_and_data.sql]

All of the examples here assume the same starting point: a table and 4 rows.
This table is very simplistic and naive, but offers a starting point to
understand the benefits of the optimizations below.

### Use an index to optimize a filter (where clause with equality)

SQL: [02_index_for_filter.sql]

A query with a filter causes a full table scan. Add an index on the columns used
for filtering to reduce the number of reads to only the number of rows returned
by the query.

### Use an index to optimize `min`, `max`, and `order` with `limit`

SQL: [03_index_for_min_max_order_limit.sql]

A query that requires an ordering of data on a column causes a full table scan.
Add an index on that column to reduce the number of reads to only the number of
row values used by the query. For example, the `min()` function requires
scanning each and every row in the table to find the lowest value, but an index
allows SQLite to find the minimum value with a single row read.

### Use triggers to maintain a table row count

SQL: [04_triggers_for_table_row_count.sql]

A query using `count()` causes a full table scan. Use triggers to maintain a
running count of rows in another table when a row is inserted or deleted from
the original table. The other table can then be queried for the count, requiring
only a single row read.

### Use triggers to maintain filtered table row counts per unique value

SQL: [05_triggers_for_filtered_row_count.sql]

Similar to above, a filtered query using `count()` causes a full table scan.
Even with an index on the column used in the filter, a scan of the matching rows
is still required to compute a count. Use triggers to maintain running unique
value counts in another table whenever a rows is inserted, updated or deleted
from the original table. The other table can then be queried for the filtered
count, requiring only a single row read.

### Use triggers to maintain an aggregate (`avg`) of all column values

SQL: [06_triggers_for_column_avg.sql]

A query using `avg()` causes a full table scan. Use triggers to maintain a
running average in another table of the values in a column when a row value is
inserted, updated, or deleted from the original table. The other table can then
be queried for the average, requiring only a single row read.

## Code to monitor usage

The nodejs program under [monitor-usage] was useful for actively monitoring the
actual usage of the test database as SQL commands were executed against it.


[billed usage]: https://docs.turso.tech/billing-details
[companion blog post]: https://blog.turso.tech
[Turso]: https://turso.tech
[Use an index]: https://www.sqlite.org/queryplanner.html
[SQLite triggers]: https://www.sqlite.org/lang_createtrigger.html
[Turso CLI]: https://docs.turso.tech/reference/turso-cli
[sqlite3 CLI]: https://www.sqlite.org/cli.html
[01_table_and_data.sql]: 01_table_and_data.sql
[02_index_for_filter.sql]: 02_index_for_filter.sql
[03_index_for_min_max_order_limit.sql]: 03_index_for_min_max_order_limit.sql
[04_triggers_for_table_row_count.sql]: 04_triggers_for_table_row_count.sql
[05_triggers_for_filtered_row_count.sql]: 05_triggers_for_filtered_row_count.sql
[06_triggers_for_column_avg.sql]: 06_triggers_for_column_avg.sql
[monitor-usage]: monitor-usage