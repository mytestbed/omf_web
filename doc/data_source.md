
# Declarations of Data Sources

Each data widget needs one or more associated data sources. A data source can be viewed
as a static or dynamic table defined by a _schema_ describing its columns and each
row representing a data item. Data sources can come
from local CSV files, databases, or OMSP streams.

A typical declaration of a data source is separated from its use in a data widget. As an example
let us look at the 'simple' demo configuration file:

    data_sources:
      - id: signal
        table: wave
        database:
          id: sample
          url: sqlite:sample.sq3

    widgets:
      ...
          - type: data/line_chart3
            data_source:
              name: signal

The top-level 'data_sources' element describes the list of available data sources identified by a
unique key 'id' which is then later referred to in the respective data widget description's
'data_source(s)' element through the 'name' field.

If a data source is only used once, it can be directly declared inside the widget declaration but
we highly discourage this practice.

__OMF Web__ currently supports the following types of data sources:

* Files
* Databases
* OMSP streams

## Static Data Source from a File

    data_sources:
      - id: sample
        file: sample.csv
        content_type: csv

The 'file' element contains a path to the content. If the path starts with a '/' is is assumed to be an
absolute path, otherwise it is assumed to be relative to the configuration file.

Currently only CSV formatted files are supported. The CSV is assumed to contain a schema
description in the first row following the __OMF_OML__ convention of comma separated
'name:type' declarations.

As an example, the following CSV file contains a table with four columns, 'id', 'from_id', 'to_id',
nad 'zone', with types 'int', 'string', 'string', int', respectively:

    id:int,from_id:string,to_id:string,zone:int
    3,10:10:10:10:10:fe,rf2,0
    ...

## Data Sources from Databases

    data_sources:
      - id: signal
        database:
          table: wave

          query: SELECT oml_ts_server as ts, val, wrid FROM webrtc_stats WHERE key='googRtt'
          schema: [[ts, float], [val, int], [wrid, string]]

          id: sample
          url: sqlite:sample.sq3

          name: sample

