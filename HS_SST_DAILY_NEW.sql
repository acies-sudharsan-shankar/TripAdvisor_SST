--Usage: 

with raw_table as
(select spa.ds, spa.location_id, spa.billing_account_id, spa.contract_number,NULL as product, spa.sl_advertiser_id, spc.sl_campaign_id,  
spa.total_spent_usd as delivered_revenue, 
spa.sp_net_revenue as net_delivered_revenue
from tripdna.b2bh.sp_location_advertiser spa
left join tripdna.b2bh.sp_location_advertiser_campaign spc
on spa.location_id = spc.location_id
and spa.sl_advertiser_id = spc.sl_advertiser_id
and spa.ds=spc.ds
where spa.location_id = 4604400
order by ds asc),

minmax as (
select location_id, sl_advertiser_id, sl_campaign_id ,min(ds) as mindate, max(ds) as maxdate
from raw_table
group by all
),

revenue as(
select spa.location_id, spa.sl_advertiser_id, spa.sl_campaign_id, tc.first_day_of_month as fmonth,
sum(spa.delivered_revenue) as delivered_revenue, sum(spa.net_delivered_revenue) as net_delivered_revenue
from raw_table spa
left join rio_sf.b2b_core.t_calendar tc
on spa.ds = tc.ds
group by all
),

dailyrecords as
(select location_id, sl_advertiser_id, sl_campaign_id, ds
from minmax mm
cross join rio_sf.b2b_core.t_calendar tc
where tc.ds between mm.mindate and mm.maxdate
),

final as
(select dr.*, tc.first_day_of_month as fmonth, r.delivered_revenue, r.net_delivered_revenue
from dailyrecords dr
left join rio_sf.b2b_core.t_calendar tc
on dr.ds = tc.ds
left join revenue r
on tc.first_day_of_month = r.fmonth)

select location_id, sl_advertiser_id, sl_campaign_id, fmonth,
sum(delivered_revenue) as delivered_revenue,
sum(net_delivered_revenue) as net_delivered_revenue
from final
group by all
order by fmonth asc;


select location_id, sl_advertiser_id,month, sum(delivered_revenue), sum(net_delivered_revenue)
from analytics.public.hs_sst_daily
where location_id = 4604400
group by all
order by 1,2,3;

------Subscription:

select ds, location_id, billing_account_id, contract_number, product, NULL as sl_advertiser_id, NULL as campaign_id  contract_billing_unit_amt_usd, contract_billing_unit_net_amt_per_location_usd
from rio_sf.b2b_core.vw_contract_location_daily
where location_id = 4604400
order by ds asc;
