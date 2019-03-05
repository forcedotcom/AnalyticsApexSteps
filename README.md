# Analytics Apex Steps

Examples for Apex Steps and some utilities to help get you started building your own Apex Steps for Einstein Analytics Dashboards.

Official [docs](https://developer.salesforce.com/docs/atlas.en-us.bi_dev_guide_json.meta/bi_dev_guide_json/bi_dbjson_steps_types_apex.htm) and some more info on building Einstein Analytics [apps](https://developer.salesforce.com/blogs/2017/10/build-apps-not-dashboards.html).

## [Common](/force-app/main/apex/common)

Some classes to help with boilerplate in parsing requests from an Apex Step and serializing results back to the Apex Step for visualization or more processing.

## [Integration](/force-app/main/apex/examples/integration)

Using Apex steps to integrate with external data sources enabled via [Remote Site Settings](https://help.salesforce.com/articleView?id=configuring_remoteproxy.htm). Several examples connecting to public APIs for stock quotes and currency conversion rates, sites used are not affiliated and were chosen purely for demo purposes.

## [Manipulation](/force-app/main/apex/examples/manipulation)

Examples of generic data manipluation steps from transposing tables to blending tables from different sources.