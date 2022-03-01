[SERVICE]
    parsers_file /fluent-bit/etc/fluent-bit-parsers.conf

[INPUT]
    name forward

[FILTER]
    name parser
    match *
    key_name log
    parser info
    parser error

[FILTER]
    name grep
    match *
    exclude log .+

[OUTPUT]
    name bigquery
    match *
    skip_invalid_rows on
    dataset_id ${bigquery.dataset_id}
    table_id ${bigquery.table_id}
