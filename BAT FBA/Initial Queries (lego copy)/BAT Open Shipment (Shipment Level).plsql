Q_SHIP
--------------------

select   s.shipment_gid SHIPMENT_ID,shinv.involved_party_qual_gid,shinv.INVOLVED_PARTY_CONTACT_GID
FROM glogowner.shipment s,glogowner.shipment_involved_party shinv, 
glogowner.contact con
where shinv.involved_party_contact_gid = con.contact_gid
--AND con.location_gid = l.location_gid
AND shinv.shipment_gid = s.shipment_gid
--AND lr.remark_qual_gid = 'LEGO.LEGAL_NAME'
AND shinv.involved_party_qual_gid = 'BILL_TO'
and s.shipment_Gid like 'LEGO.%' and not exists (select 1
from glogowner.Ie_Shipmentstatus ies,glogowner.ss_status_history ssh 
where 
ies.status_code_gid='LEGO.COST OK' and ssh.shipment_gid like 'LEGO%'
and ssh.shipment_gid = s.shipment_gid
and Ies.I_Transaction_No=ssh.I_Transaction_No) and
((shinv.INVOLVED_PARTY_CONTACT_GID = :P_BILL_TO_LEGAL_NAME) or :P_BILL_TO_LEGAL_NAME IS NULL)
and trunc(utc.get_local_date(s.start_time,s.source_location_gid)) BETWEEN TO_DATE(:P_COLLECTION_FROM_DATE,:P_DATE_FORMAT) AND TO_DATE(:P_COLLECTION_TO_DATE,:P_DATE_FORMAT)
AND (TO_DATE(:P_COLLECTION_TO_DATE,:P_DATE_FORMAT) - TO_DATE(:P_COLLECTION_FROM_DATE,:P_DATE_FORMAT)) <= 31


Q_1
------------------------
select OTM_SHIPMENT_NUMBER
,OTM_INVOICE_CURRENCY
,OTM_INVOICE_VALUE 
,CARRIER_INVOICE_RECEIPT_DATE
,CARRIER_INVOICE_VALUE_MATCHED
,OTM_SHIPMENT_CURRENCY_GID
,SHIPMENT_TOTAL_ACTUAL_COST 
,INVOICE_STATUS_DATE
,BILL_TO_LEGAL_NAME
,BILL_TO_ADDRESS
,SHIPMENT_BASE_COST
,SHIPMENT_ACCESSORIAL_COST 
,TOTAL_FUEL_SURCHARGE
,FBA_PROCESS_MODE
,OTM_COST_OK_DATE
,DOP_CONSIGNMENT_NUMBER
,ORDER_TYPE
,ORDER_RELEASE_ID
,GROSS_WEIGHT
,ACTUAL_CHARGEABLE_WEIGHT
,SHIPMENT_COLLECTION_DATE
,SHIPMENT_DELIVERY_DATE
,LANE_ID
,RATES_EFFECTIVE_FROM
,RATES_EFFECTIVE_TO
,TRANSPORT_MODE
,EQUIPMENT_TYPE
,COLLECTION_POINT_NAME
,COLLECTION_POINT_CITY
,COLLECTION_POINT_COUNTRY
,COLLECTION_POINT_ID
,DELIVERY_POINT_NAME
,DELIVERY_POINT_CITY
,DELIVERY_POINT_COUNTRY 
,DELIVERY_POINT_ID
,CARRIER_NAME
,CARRIER_ADDRESS
,CARRIER_OTM_ID
,CARRIER_COUNTRY
,OTM_INVOICE_ID
,CARRIER_INVOICE_NUMBER
,CARRIER_INVOICE_DATE
,round(NVL(SHIPMENT_BASE_COST,0)+NVL(SHIPMENT_ACCESSORIAL_COST,0)+NVL(TOTAL_FUEL_SURCHARGE,0),2) TOTAL_FREIGHT_FUEL
,round(DELAYS_TOTAL,2)DELAYS_TOTAL
,round(CANCELLATION_CHARGE,2)CANCELLATION_CHARGE
,round(MISCELLANEOUS,2)MISCELLANEOUS
,PMER_EXCHANGE_RATE
,OTM_SHIPMENT_STATUS
,COST_OK
,OTM_INVOICE_STATUS
,CUSTOMER_SALES
,APPORTIONED_OTM_SHIPMENT
,OTM_INVOICE_AMOUNT_NET
,VAT_AMOUNT
,OTM_INVOICE_AMOUNT_GROSS
,INVOICE_CURRENCY
,TREATMENT_CODE
,FBA_RESPONSIBILITY_STATUS
,BILL_TO_VAT_NUMBER
,CARRIER_VAT_NUMBER
from(

with temp as(select shipment_Gid,leg,description,sum(cost)cost from(
select 
s.shipment_gid
,case when sr.shipment_refnum_value in('DIRECT','NO_VALUE') then 'LEG2' else sr.shipment_refnum_value end leg
,(case  
when sc.ACCESSORIAL_CODE_GID in
('LEGO.DEMURRAGE',
'LEGO.WAITING_TIME',
'LEGO.WAITING_TIME_CHARGE_PER_HR')
 then
  'COST4'
when sc.ACCESSORIAL_CODE_GID in 
('LEGO.CANCELLATION',
'LEGO.CANCELLATION_PERCENT',
'LEGO.REFUSAL',
'LEGO.REFUSAL_AS_PERCENTAGE_OF_DELIVERY')
 then
  'COST5'
/* ************ LEG 1 ************ */
when sr.shipment_refnum_value='LEG1' and  sc.COST_TYPE= 'B' then
'COST1'
when (sr.shipment_refnum_value='LEG1' and sc.cost_type ='A' and  sc.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when (sr.shipment_refnum_value='LEG1' and sc.cost_type ='A' and  sc.ACCESSORIAL_CODE_GID IN 
('LEGO.AIR_DESTINATION_HANDLING',
'LEGO.AIR_ORIGIN_HANDLING',
'LEGO.AIRPORT_HANDLING',
'LEGO.HANDLING_AIR',
'LEGO.HANDLING_CHARGE',
'LEGO.LCL_DESTINATION_HANDLING',
'LEGO.LCL_ORIGIN_HANDLING',
'LEGO.PORT_TERMINAL_HANDLING',
'LEGO.TERMINAL_HANDLING_CHARGES',
'LEGO.CONTAINER_DE-STUFFING',
'LEGO.CONTAINER_STUFFING_CHARGES',
'LEGO.ORIGIN_CONTAINER_STUFFING',
'LEGO.WHARFAGE',
'LEGO.BILL_OF_LADING',
'LEGO.SWITCH_BILL_OF_LADING',
'LEGO.HAZARDOUS',
'LEGO.HAZARDOUS_FIXED',
'LEGO.HAZARDOUS_PERCENT',
'LEGO.EXPORT_CUSTOMS_CLEARANCE',
'LEGO.ENS',
'LEGO.ORIGIN_OTHER_COSTS',
'LEGO.OTHER_CHARGE1',
'LEGO.OTHER_CHARGE2',
'LEGO.OTHER_CHARGE3',
'LEGO.OTHER_CHARGES',
'LEGO.OTHER_COST_A',
'LEGO.ROAD_OTHER_COSTS',
'LEGO.FERRY_CHARGE'
)) then
'COST3'
when sr.shipment_refnum_value='LEG1' then
'OTHERS'
/* ************ LEG 2 ************ */
when sr.shipment_refnum_value  in('LEG2','DIRECT','NO_VALUE') and  sc.COST_TYPE= 'B' then
'COST1'
when (sr.shipment_refnum_value  in('LEG2','DIRECT','NO_VALUE') and sc.cost_type ='A' and  sc.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when (sr.shipment_refnum_value in('LEG2','DIRECT','NO_VALUE') and  (sc.cost_type='S' or  sc.ACCESSORIAL_CODE_GID in
('LEGO.BAF',
'LEGO.CAF',
'LEGO.ROAD_TAX_CHARGE_TOLLS',
'LEGO.T1_DOCUMENT',
'LEGO.EXPORT_CUSTOMS_CLEARANCE',
'LEGO.IMPORT_CUSTOMS_CLEARANCE',
'LEGO.TAIL_LIFT_CHARGE',
'LEGO.AIR_SECURITY_FEE',
'LEGO.INT_SHIP_PORT_SECURITY',
'LEGO.LASHING_AND_SECURING',
'LEGO.SECURITY',
'LEGO.PIRACY_AND_RISK',
'LEGO.GULF_OF_ADEN_COST',
'LEGO.SUEZ_COST',
'LEGO.DEST_HEAVY_WEIGHT',
'LEGO.HEAVY_WEIGHT',
'LEGO.DESTINATION_OTHER_COSTS',
'LEGO.ORIGIN_OTHER_COSTS',
'LEGO.OTHER_CHARGE1',
'LEGO.OTHER_CHARGE2',
'LEGO.OTHER_CHARGE3',
'LEGO.OTHER_CHARGES',
'LEGO.OTHER_COST_A',
'LEGO.ROAD_OTHER_COSTS',
'LEGO.HAZARDOUS',
'LEGO.HAZARDOUS_FIXED',
'LEGO.HAZARDOUS_PERCENT',
'LEGO.SOLAS_CHARGE',
'LEGO.SOLAS_CHECK_WEIGHT_FEE',
'LEGO.SOLAS_VGA_FEE',
'LEGO.FERRY_CHARGE'
) )) then
 'COST3'
when sr.shipment_refnum_value in('LEG2','DIRECT','NO_VALUE') then
'OTHERS' 
/* ************ LEG 3 ************ */
when sr.shipment_refnum_value ='LEG3'  and  sc.COST_TYPE= 'B' then
'COST1'
when (sr.shipment_refnum_value ='LEG3'  and sc.cost_type ='A' and  sc.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when sr.shipment_refnum_value='LEG3' and   sc.ACCESSORIAL_CODE_GID in 
('LEGO.AIR_DESTINATION_HANDLING',
'LEGO.AIR_ORIGIN_HANDLING',
'LEGO.AIRPORT_HANDLING',
'LEGO.HANDLING_AIR',
'LEGO.HANDLING_CHARGE',
'LEGO.LCL_DESTINATION_HANDLING',
'LEGO.LCL_ORIGIN_HANDLING',
'LEGO.PORT_TERMINAL_HANDLING',
'LEGO.TERMINAL_HANDLING_CHARGES',
'LEGO.AIR_SECURITY_FEE',
'LEGO.INT_SHIP_PORT_SECURITY',
'LEGO.LASHING_AND_SECURING',
'LEGO.SECURITY',
'LEGO.PIRACY_AND_RISK',
'LEGO.HAZARDOUS',
'LEGO.HAZARDOUS_FIXED',
'LEGO.HAZARDOUS_PERCENT',
'LEGO.IMPORT_CUSTOMS_CLEARANCE',
'LEGO.DESTINATION_CUSTOMS_CLEARANCE',
'LEGO.DOCUMENTATION',
'LEGO.T1_DOCUMENT',
'LEGO.DESTINATION_OTHER_COSTS',
'LEGO.ORIGIN_OTHER_COSTS',
'LEGO.OTHER_CHARGE1',
'LEGO.OTHER_CHARGE2',
'LEGO.OTHER_CHARGE3',
'LEGO.OTHER_CHARGES',
'LEGO.OTHER_COST_A',
'LEGO.ROAD_OTHER_COSTS',
'LEGO.FERRY_CHARGE'
) then
'COST3'
when sr.shipment_refnum_value='LEG3' then
'OTHERS' 
end)  description

,(sc.cost*(select cer.exchange_rate from currency_exchange_rate cer where 
   cer.effective_date=(select max(cer2.effective_date) from currency_exchange_rate cer2 where  
   cer2.effective_date<=s.start_time and
   cer2.from_currency_gid=sc.cost_gid and 
   cer2.to_currency_gid=s.T_ACTUAL_COST_CURRENCY_GID and
   cer2.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' ) and 	
   cer.from_currency_gid=sc.cost_gid and 
   cer.to_currency_gid=s.T_ACTUAL_COST_CURRENCY_GID and
   cer.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' and rownum=1)) cost

From 
shipment_Refnum sr,
shipment_cost sc ,
shipment s
where 
sr.shipment_refnum_qual_gid='LEGO.LEG' and
sr.shipment_gid=s.shipment_gid and 
sc.shipment_gid=s.shipment_gid and 
s.shipment_Gid =:SHIPMENT_ID) group by shipment_Gid, leg, description)
/* ********* Main query *********** */
select 
s.shipment_xid OTM_Shipment_Number
,(select listagg(replace(orl.ORDER_RELEASE_TYPE_GID,'LEGO.'),',') within group (order by 1)
  from order_Release orl, order_movement om
where 
orl.order_Release_Gid=om.order_Release_gid and 
om.shipment_Gid=s.shipment_gid) Order_Type
,(select listagg(orl.order_Release_xid,',') within group (order by 1)
  from order_Release orl, order_movement om
where 
orl.order_Release_Gid=om.order_Release_gid and 
om.shipment_Gid=s.shipment_gid) Order_Release_ID
,(ROUND(s.TOTAL_WEIGHT,2) || ' ' || s.TOTAL_WEIGHT_UOM_CODE) Gross_Weight
,(select listagg((round(orl.TOTAL_NET_WEIGHT,2) || ' ' || orl.TOTAL_NET_WEIGHT_UOM_CODE),',') within group (order by 1)from order_Release orl, order_movement om where orl.order_Release_Gid=om.order_Release_gid and 
om.shipment_Gid=s.shipment_gid and om.SHIPMENT_GID=:SHIPMENT_ID) Actual_Chargeable_Weight
,NVL((TO_CHAR(TO_DATE((S.ATTRIBUTE3),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')),TO_CHAR(UTC.GET_LOCAL_DATE(S.START_TIME,S.SOURCE_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))AS SHIPMENT_COLLECTION_DATE
,NVL((TO_CHAR(TO_DATE((S.ATTRIBUTE4),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')),TO_CHAR(UTC.GET_LOCAL_DATE(S.END_TIME,S.DEST_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))AS SHIPMENT_DELIVERY_DATE
,replace(s.RATE_GEO_GID,'LEGO.')Lane_id
,(SELECT to_char(rg.EFFECTIVE_DATE,'DD/MM/YYYY hh24:mi:ss') FROM rate_geo rg where rg.RATE_GEO_GID=s.RATE_GEO_GID) Rates_Effective_From
,(SELECT to_char(rg.EXPIRATION_DATE,'DD/MM/YYYY hh24:mi:ss') FROM rate_geo rg where rg.RATE_GEO_GID=s.RATE_GEO_GID) Rates_Effective_to
,replace(s.transport_mode_gid,'LEGO.')transport_Mode
,replace(s.FIRST_EQUIPMENT_GROUP_GID,'LEGO.') Equipment_Type
,(select l.location_name from glogowner.location l where l.location_gid=s.source_location_gid) COLLECTION_POINT_NAME
,(select l.city from glogowner.location l where l.location_gid=s.source_location_gid)COLLECTION_POINT_CITY
,(select l.COUNTRY_CODE3_GID from glogowner.location l where l.location_gid=s.source_location_gid)COLLECTION_POINT_COUNTRY
,(select l.location_xid from glogowner.location l where l.location_gid=s.source_location_gid)COLLECTION_POINT_ID
,(select l.location_name from glogowner.location l where l.location_gid=s.dest_location_gid) DELIVERY_POINT_NAME
,(select l.city from glogowner.location l where l.location_gid=s.dest_location_gid)DELIVERY_POINT_CITY
,(select l.COUNTRY_CODE3_GID from glogowner.location l where l.location_gid=s.dest_location_gid)DELIVERY_POINT_COUNTRY
,(select l.location_xid from glogowner.location l where l.location_gid=s.dest_location_gid)DELIVERY_POINT_ID
,(select l.location_name from location l where l.location_gid = s.servprov_gid)Carrier_Name
,(SELECT (SELECT  LISTAGG(la.address_line, '::') WITHIN GROUP(ORDER BY la.line_sequence) FROM location_address la WHERE la.location_gid=l.location_gid)||'::'||l.city||'::'||l.postal_code||'::'||l.country_code3_gid  FROM location l,shipment  s WHERE l.location_gid=s.servprov_gid  and s.shipment_gid= :SHIPMENT_ID)CARRIER_ADDRESS
,replace(s.SERVPROV_GID,'LEGO.') CARRIER_OTM_ID
,(select l.COUNTRY_CODE3_GID from location l where l.location_gid = s.servprov_gid)Carrier_country
,null OTM_Invoice_ID	
,null  Carrier_Invoice_Number
,null  Carrier_Invoice_Date
,(select sum(t.cost) from temp t where    t.description='COST4' and t.shipment_gid=s.shipment_Gid)Delays_total 
,(select sum(t.cost) from temp t where    t.description='COST5' and t.shipment_gid=s.shipment_Gid)Cancellation_charge 
,(select sum(t.cost) from temp t where    t.description='OTHERS' and t.shipment_gid=s.shipment_Gid)Miscellaneous 
,(SELECT round(SHIPMENT_REFNUM_VALUE,2) FROM  SHIPMENT_REFNUM sr WHERE  sr.SHIPMENT_REFNUM_QUAL_GID='LEGO.EUR_EXCHANGE_RATE' and sr.shipment_gid=s.shipment_GID) PMER_Exchange_rate
,null OTM_INVOICE_CURRENCY
,null OTM_INVOICE_VALUE 
,null CARRIER_INVOICE_RECEIPT_DATE
,null CARRIER_INVOICE_VALUE_MATCHED
,null INVOICE_STATUS_DATE
,s.CURRENCY_GID  OTM_SHIPMENT_CURRENCY_GID
,round(s.TOTAL_ACTUAL_COST,2)  SHIPMENT_TOTAL_ACTUAL_COST
,(SELECT l.location_name FROM location                 l, shipment_involved_party  sip
 WHERE   l.location_gid=sip.involved_party_contact_gid AND sip.involved_party_qual_gid='BILL_TO'
 AND sip.shipment_gid= :SHIPMENT_ID) BILL_TO_LEGAL_NAME 
,(SELECT (SELECT  LISTAGG(la.address_line, '::') WITHIN GROUP(ORDER BY la.line_sequence) FROM location_address la WHERE
la.location_gid=l.location_gid)||'::'||l.city||'::'||l.postal_code||'::'||l.country_code3_gid  FROM location l,shipment_involved_party  sip
WHERE l.location_gid=sip.involved_party_contact_gid  AND sip.involved_party_qual_gid='BILL_TO' AND sip.shipment_gid= :SHIPMENT_ID
)BILL_TO_ADDRESS 
,(select ROUND(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='B'  AND sc.shipment_gid=:SHIPMENT_ID) SHIPMENT_BASE_COST
,(select ROUND(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='A'  AND sc.shipment_gid=:SHIPMENT_ID) SHIPMENT_ACCESSORIAL_COST 
,(select ROUND(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='A' and sc.ACCESSORIAL_CODE_GID='LEGO.FUEL SURCHARGE' AND sc.shipment_gid=:SHIPMENT_ID) TOTAL_FUEL_SURCHARGE
 ,(select  listagg(sr.shipment_Refnum_value,',') within group (order by 1) From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid and rownum=1) FBA_PROCESS_MODE
,TO_CHAR(TO_DATE((S.ATTRIBUTE_DATE5),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')  OTM_COST_OK_DATE
,(select  listagg(orr.order_Release_refnum_value,',') within group (order by 1)  from glogowner.order_Release_refnum  orr,glogowner.order_movement om  where 
orr.order_Release_Refnum_qual_gid in('LEGO.ORDER_NUMBER') and  
orr.order_Release_gid=om.order_Release_gid and om.shipment_gid=s.shipment_gid and rownum=1) DOP_CONSIGNMENT_NUMBER
,s.attribute1 OTM_Shipment_Status
,(select to_char(ies.EVENTDATE,'DD/MM/YYYY HH24:mi:ss')||' '||time_zone_gid 

from Ie_Shipmentstatus ies,ss_status_history ssh
where 
ies.I_Transaction_No=(select max(ies2.I_Transaction_No) from IE_SHIPMENTSTATUS ies2 where ies2.shipment_gid=s.shipment_gid and ies2.status_code_gid='LEGO.COST OK') and 
ies.status_code_gid='LEGO.COST OK' and Ies.I_Transaction_No=ssh.I_Transaction_No and  
ssh.shipment_gid=s.shipment_gid)Cost_Ok

,null OTM_Invoice_status
,(select  listagg(orr.order_Release_refnum_value,',') within group (order by 1)  from order_Release_refnum  orr,order_movement om  where 
orr.order_Release_Refnum_qual_gid='LEGO.SALES_ORG' and  
orr.order_Release_gid=om.order_Release_gid and om.shipment_gid=s.shipment_gid) Customer_Sales
,(select listagg(round(a.TOTAL_ALLOC_COST,2),',') within group (order by 1) from GLOGOWNER.allocation_base AB,GLOGOWNER.ALLOCATION A where AB.ALLOC_TYPE_QUAL_GID='PLANNING' and AB.shipment_gid=:SHIPMENT_ID AND A.SHIPMENT_GID=AB.SHIPMENT_GID AND A.ALLOC_SEQ_NO=AB.ALLOC_SEQ_NO)APPORTIONED_OTM_SHIPMENT,

(select inv.ATTRIBUTE11 from invoice_shipment invs,invoice inv where 
invs.invoice_gid=inv.invoice_gid and invs.shipment_gid=s.shipment_gid) OTM_INVOICE_AMOUNT_NET,

(select inv.ATTRIBUTE12 from invoice_shipment invs,invoice inv where invs.invoice_gid=inv.invoice_gid and invs.shipment_gid=s.shipment_gid) 
VAT_AMOUNT,

(select inv.ATTRIBUTE13 from invoice_shipment invs,invoice inv where invs.invoice_gid=inv.invoice_gid and invs.shipment_gid=s.shipment_gid)
OTM_INVOICE_AMOUNT_GROSS,

(select inv.ATTRIBUTE14 from invoice_shipment invs,invoice inv where invs.invoice_gid=inv.invoice_gid and 
invs.shipment_gid=s.shipment_gid) INVOICE_CURRENCY,

(select glog_util.remove_domain(VAT_CODE_GID) from vat_analysis VA, invoice_shipment invs where VA.invoice_gid=invs.invoice_gid and 
invs.shipment_gid = s.shipment_gid) TREATMENT_CODE,

(SELECT SR.SHIPMENT_REFNUM_VALUE FROM SHIPMENT_REFNUM SR where sr.shipment_gid =:SHIPMENT_ID and sr.SHIPMENT_REFNUM_QUAL_GID='LEGO.LLP_RESPONSIBILITY')
FBA_RESPONSIBILITY_STATUS,

(SELECT loc_rem.remark_text FROM  location  l, shipment_involved_party  sip,location_remark    loc_rem
WHERE l.location_gid=sip.involved_party_contact_gid AND loc_rem.location_gid=l.location_gid 
AND sip.involved_party_qual_gid='BILL_TO' AND loc_rem.remark_qual_gid='LEGO.BILL_TO_VAT_NUMBER' AND sip.shipment_gid=:SHIPMENT_ID) BILL_TO_VAT_NUMBER,
(SELECT sr.remark_text FROM shipment_remark sr WHERE sr.remark_qual_gid='LEGO.OTM_CARRIER_VAT_NUMBER' AND sr.shipment_gid=:SHIPMENT_ID) CARRIER_VAT_NUMBER
from 
shipment s where 
not exists(select 1 from invoice_shipment invs where invs.shipment_gid=s.shipment_gid ) 
AND  (:P_FBA_OTM_RESPONSIBILITY in (select  SR.shipment_refnum_value  from shipment_refnum  sr where 
SR.shipment_refnum_qual_gid='LEGO.LLP_RESPONSIBILITY' and sr.shipment_gid = s.shipment_gid) 
or :P_FBA_OTM_RESPONSIBILITY IS NULL)  
and not exists (select 1
from Ie_Shipmentstatus ies,ss_status_history ssh
where ies.status_code_gid='LEGO.COST OK' and Ies.I_Transaction_No=ssh.I_Transaction_No and  ssh.shipment_gid=s.shipment_gid)
and s.shipment_gid=:SHIPMENT_ID)