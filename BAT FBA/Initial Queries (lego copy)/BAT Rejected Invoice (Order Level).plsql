Q_1
-------------------------------
select 
OTM_SHIPMENT_NUMBER
,ORDER_RELEASE_ID
,ORDER_TYPE
,CUSTOMER_SALES
,FBA_RESPONSIBILITY_STATUS
,BILL_TO_LEGAL_NAME 
,BILL_TO_ADDRESS
,BILL_TO_VAT_NUMBER
,OTM_INVOICE_ID
,CARRIER_INVOICE_NUMBER
,CARRIER_INVOICE_DATE
,CARRIER_INVOICE_RECEIPT_DATE
,CARRIER_NAME
,CARRIER_ADDRESS
,CARRIER_VAT_NUMBER
,CARRIER_OTM_ID
,CARRIER_COUNTRY
,SHIPMENT_COLLECTION_DATE
,SHIPMENT_DELIVERY_DATE
,COLLECTION_POINT_NAME
,COLLECTION_POINT_CITY
,COLLECTION_POINT_COUNTRY
,COLLECTION_POINT_ID
,DELIVERY_POINT_NAME
,DELIVERY_POINT_CITY
,DELIVERY_POINT_COUNTRY 
,DELIVERY_POINT_ID
,TRANSPORT_MODE
,EQUIPMENT_TYPE
,LANE_ID
,RATES_EFFECTIVE_FROM
,RATES_EFFECTIVE_TO
,GROSS_WEIGHT
,ACTUAL_CHARGEABLE_WEIGHT 
,SHIPMENT_BASE_COST
,TOTAL_FUEL_SURCHARGE
,round(DELAYS_TOTAL,2)DELAYS_TOTAL
,round(CANCELLATION_CHARGE,2)CANCELLATION_CHARGE
,round(MISCELLANEOUS,2)MISCELLANEOUS
,SHIPMENT_ACCESSORIAL_COST 
,SHIPMENT_TOTAL_ACTUAL_COST
,VAT_AMOUNT
,APPORTIONED_OTM_SHIPMENT
,OTM_INVOICE_AMOUNT_NET
,OTM_INVOICE_AMOUNT_GROSS
,CARRIER_INVOICE_VALUE_MATCHED
,OTM_INVOICE_CURRENCY
,COST_OK
,OTM_COST_OK_DATE
,OTM_INVOICE_STATUS
,INVOICE_STATUS_DATE
,OTM_SHIPMENT_STATUS
,FBA_PROCESS_MODE           
,PMER_EXCHANGE_RATE              
,OTM_INVOICE_VALUE
,OTM_SHIPMENT_CURRENCY_GID
,round(NVL(SHIPMENT_BASE_COST,0)+NVL(SHIPMENT_ACCESSORIAL_COST,0)+NVL(TOTAL_FUEL_SURCHARGE,0),2) TOTAL_FREIGHT_FUEL
,DOP_CONSIGNMENT_NUMBER
,INVOICE_CURRENCY
,TREATMENT_CODE
 from(

with temp as(select shipment_Gid, order_Release_gid,leg,description,sum(cost)cost from(
select 
s.shipment_Gid
,om.order_Release_gid
,case when sr.shipment_refnum_value in('DIRECT','NO_VALUE') then 'LEG2' else sr.shipment_refnum_value end leg
,(case  
when aord.ACCESSORIAL_CODE_GID in
('LEGO.DEMURRAGE',
'LEGO.WAITING_TIME',
'LEGO.WAITING_TIME_CHARGE_PER_HR')
 then
  'COST4'
when aord.ACCESSORIAL_CODE_GID in 
('LEGO.CANCELLATION',
'LEGO.CANCELLATION_PERCENT',
'LEGO.REFUSAL',
'LEGO.REFUSAL_AS_PERCENTAGE_OF_DELIVERY')
 then
  'COST5'
/* ************ LEG 1 ************ */
when sr.shipment_refnum_value='LEG1' and  aord.cost_description= 'B' then
'COST1'
when (sr.shipment_refnum_value='LEG1' and aord.cost_description ='A' and  aord.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when (sr.shipment_refnum_value='LEG1' and aord.cost_description ='A' and  aord.ACCESSORIAL_CODE_GID IN 
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
when sr.shipment_refnum_value  in('LEG2','DIRECT','NO_VALUE') and  aord.cost_description= 'B' then
'COST1'
when (sr.shipment_refnum_value  in('LEG2','DIRECT','NO_VALUE') and aord.cost_description ='A' and  aord.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when (sr.shipment_refnum_value in('LEG2','DIRECT','NO_VALUE') and  (aord.cost_description='S' or  aord.ACCESSORIAL_CODE_GID in
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
when sr.shipment_refnum_value ='LEG3'  and  aord.cost_description= 'B' then
'COST1'
when (sr.shipment_refnum_value ='LEG3'  and aord.cost_description ='A' and  aord.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when sr.shipment_refnum_value='LEG3' and   aord.ACCESSORIAL_CODE_GID in 
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


,case when ab.invoice_gid is null then 
(aord.cost*(select cer.exchange_rate from glogowner.currency_exchange_rate cer where 
   cer.effective_date=(select max(cer2.effective_date) from glogowner.currency_exchange_rate cer2 where  
   cer2.effective_date<=s.start_time and
   cer2.from_currency_gid=aord.cost_currency_gid and 
   cer2.to_currency_gid=s.T_ACTUAL_COST_CURRENCY_GID and
   cer2.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' ) and 	
   cer.from_currency_gid=aord.cost_currency_gid and 
   cer.to_currency_gid=s.T_ACTUAL_COST_CURRENCY_GID and
   cer.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' and rownum=1)) 
else
-1*(aord.cost*(select cer.exchange_rate from glogowner.currency_exchange_rate cer where 
   cer.effective_date=(select max(cer2.effective_date) from glogowner.currency_exchange_rate cer2 where  
   cer2.effective_date<=s.start_time and
   cer2.from_currency_gid=aord.cost_currency_gid and 
   cer2.to_currency_gid=s.T_ACTUAL_COST_CURRENCY_GID and
   cer2.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' ) and 	
   cer.from_currency_gid=aord.cost_currency_gid and 
   cer.to_currency_gid=s.T_ACTUAL_COST_CURRENCY_GID and
   cer.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' and rownum=1)) 
end cost

From 
glogowner.ALLOCATION_BASE ab,
glogowner.allocation_order_release_d aord,
glogowner.order_movement om,
glogowner.shipment_Refnum sr,
glogowner.shipment s
where 
ab.alloc_seq_no=aord.alloc_seq_no and 
aord.order_release_gid=om.order_release_gid and 
om.shipment_Gid=s.shipment_Gid and 
sr.shipment_refnum_qual_gid='LEGO.LEG' and
sr.shipment_gid=s.shipment_gid and 
s.shipment_Gid =S.SHIPMENT_GID
and om.order_release_gid = om.order_release_Gid) group by shipment_Gid,order_Release_gid, leg, description)


/* ********* Main query *********** */
select 
s.shipment_gid
,s.shipment_xid OTM_Shipment_Number
,replace(orl.ORDER_RELEASE_TYPE_GID,'LEGO.')  Order_Type
 ,orl.order_Release_xid Order_Release_ID
,(round(orl.TOTAL_WEIGHT,2) || ' ' || orl.TOTAL_WEIGHT_UOM_CODE) Gross_Weight
,(select listagg((round(orl.TOTAL_NET_WEIGHT,2) || ' ' || orl.TOTAL_NET_WEIGHT_UOM_CODE),',') within group (order by 1)from order_Release orl, order_movement om where orl.order_Release_Gid=om.order_Release_gid and 
om.shipment_Gid=s.shipment_gid) Actual_Chargeable_Weight
,s.CHARGEABLE_WEIGHT
,s.CHARGEABLE_WEIGHT_UOM_CODE
,NVL((TO_CHAR(TO_DATE((S.ATTRIBUTE3),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')),TO_CHAR(UTC.GET_LOCAL_DATE(S.START_TIME,S.SOURCE_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))AS SHIPMENT_COLLECTION_DATE
,NVL((TO_CHAR(TO_DATE((S.ATTRIBUTE4),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')),TO_CHAR(UTC.GET_LOCAL_DATE(S.END_TIME,S.DEST_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))AS SHIPMENT_DELIVERY_DATE
,replace(s.RATE_GEO_GID,'LEGO.')Lane_id
,(SELECT to_char(rg.EFFECTIVE_DATE,'DD/MM/YYYY hh24:mi:ss') FROM glogowner.rate_geo rg where rg.RATE_GEO_GID=s.RATE_GEO_GID) Rates_Effective_From
,(SELECT to_char(rg.EXPIRATION_DATE,'DD/MM/YYYY hh24:mi:ss') FROM glogowner.rate_geo rg where rg.RATE_GEO_GID=s.RATE_GEO_GID) Rates_Effective_to
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
,(select l.location_name from glogowner.location l where l.location_gid = s.servprov_gid)Carrier_Name
,(select listagg(l.ADDRESS_LINE,', ') within group (order by 1) from location_address l where l.location_gid = s.servprov_gid) CARRIER_ADDRESS
,replace(s.SERVPROV_GID,'LEGO.') CARRIER_OTM_ID
,(select l.COUNTRY_CODE3_GID from glogowner.location l where l.location_gid = s.servprov_gid)Carrier_country
,inv.invoice_xid||DECODE(inv.CONSOLIDATION_TYPE,'CHILD',', '||replace(inv.PARENT_INVOICE_GID,'LEGO.'))  OTM_Invoice_ID	
,inv.invoice_number Carrier_Invoice_Number
,to_char(inv.invoice_date,'DD/MM/YYYY hh24:mi:ss')Carrier_Invoice_Date
,round(inv.NET_AMOUNT_DUE,2) OTM_INVOICE_VALUE
,inv.NET_AMOUNT_DUE_GID OTM_INVOICE_CURRENCY
,case when (select sr.shipment_Refnum_value From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid)='MANUAL' THEN
    to_char(inv.ATTRIBUTE_DATE4,'DD/MM/YYYY HH24:MI:SS')
else
(select TO_CHAR(TO_DATE((IR.REMARK_TEXT),'YYYYMMDD'),'DD/MM/YYYY HH24:MI:SS') from glogowner.invoice_remark ir where 
ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_INVOICE_RECEIPT_DATE' and ir.invoice_gid=inv.invoice_gid )
end  CARRIER_INVOICE_RECEIPT_DATE
,case when (select sr.shipment_Refnum_value From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid)='MANUAL' THEN
    inv.Attribute11 || ' ' ||  inv.Attribute14
else
(select remark_text from glogowner.invoice_remark ir where 
ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_TOTAL_COST_WITH_VAT' and ir.invoice_gid=inv.invoice_gid) 
end CARRIER_INVOICE_VALUE_MATCHED
,s.CURRENCY_GID  OTM_SHIPMENT_CURRENCY_GID
,ROUND(s.TOTAL_ACTUAL_COST,2)  SHIPMENT_TOTAL_ACTUAL_COST
,(select to_char(i_s.update_date,'DD/MM/YYYY hh24:mi:ss') from invoice_status i_s where i_s.status_type_gid = 'LEGO.APPROVAL' and i_s.invoice_gid = inv.invoice_gid) INVOICE_STATUS_DATE 
,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='B'  AND sc.shipment_gid=s.shipment_gid) SHIPMENT_BASE_COST
,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='A'  AND sc.shipment_gid=s.shipment_gid) SHIPMENT_ACCESSORIAL_COST 
 ,(select  listagg(sr.shipment_Refnum_value,',') within group (order by 1) From GLOGOWNER.shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid)FBA_PROCESS_MODE 

,(SELECT l.location_name FROM location                 l, shipment_involved_party  sip
 WHERE   l.location_gid=sip.involved_party_contact_gid AND sip.involved_party_qual_gid='BILL_TO'
 AND sip.shipment_gid= s.shipment_gid) BILL_TO_LEGAL_NAME 
 
,(SELECT (SELECT  LISTAGG(la.address_line, '::') WITHIN GROUP(ORDER BY la.line_sequence) FROM location_address la WHERE
la.location_gid=l.location_gid)||'::'||l.city||'::'||l.postal_code||'::'||l.country_code3_gid  FROM location l,shipment_involved_party  sip
WHERE l.location_gid=sip.involved_party_contact_gid  AND sip.involved_party_qual_gid='BILL_TO' AND sip.shipment_gid= S.SHIPMENT_GID
)BILL_TO_ADDRESS

,(select  listagg(orr.order_Release_refnum_value,',') within group (order by 1)  from glogowner.order_Release_refnum  orr,glogowner.order_movement om  where 
orr.order_Release_Refnum_qual_gid in('LEGO.ORDER_NUMBER') and  
orr.order_Release_gid=om.order_Release_gid and om.shipment_gid=s.shipment_gid and orr.order_release_gid = om.order_release_Gid) DOP_CONSIGNMENT_NUMBER
 ,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='A' and sc.ACCESSORIAL_CODE_GID='LEGO.FUEL SURCHARGE' AND sc.shipment_gid=S.SHIPMENT_GID) TOTAL_FUEL_SURCHARGE
,TO_CHAR(s.ATTRIBUTE_DATE5,'DD/MM/YYYY HH24:MI:SS')  OTM_COST_OK_DATE
,(select sum(t.cost) from temp t where    t.description='COST4' and t.order_Release_Gid=orl.order_Release_Gid and orl.order_Release_Gid = om.order_release_Gid)Delays_total 
,(select sum(t.cost) from temp t where    t.description='COST5' and t.order_Release_Gid=orl.order_Release_Gid and orl.order_Release_Gid = om.order_release_Gid)Cancellation_charge 
,(select sum(t.cost) from temp t where    t.description='OTHERS' and t.order_Release_Gid=orl.order_Release_Gid and orl.order_Release_Gid = om.order_release_Gid)Miscellaneous 
,(SELECT round(SHIPMENT_REFNUM_VALUE,2) FROM  SHIPMENT_REFNUM sr WHERE  sr.SHIPMENT_REFNUM_QUAL_GID='LEGO.EUR_EXCHANGE_RATE' and sr.shipment_gid=s.shipment_GID)PMER_Exchange_rate
,s.attribute1 OTM_Shipment_Status
,CASE WHEN s.ATTRIBUTE_DATE5 IS NOT NULL THEN 
	   'COST OK'
	  else ''
	  end cost_ok

,inv.ATTRIBUTE2 OTM_Invoice_status
,(select  listagg(orr.order_Release_refnum_value,',') within group (order by 1)  from glogowner.order_Release_refnum  orr  where 
orr.order_Release_Refnum_qual_gid='LEGO.SALES_ORG' and  
orr.order_Release_gid=orl.order_Release_gid) Customer_Sales
,(select listagg(round(a.TOTAL_ALLOC_COST,2),',') within group (order by 1) from GLOGOWNER.allocation_base AB,GLOGOWNER.ALLOCATION A where AB.ALLOC_TYPE_QUAL_GID='PLANNING' and AB.shipment_gid=s.shipment_gid
AND A.SHIPMENT_GID=AB.SHIPMENT_GID AND A.ALLOC_SEQ_NO=AB.ALLOC_SEQ_NO AND A.ORDER_RELEASE_GID= om.order_release_Gid)APPORTIONED_OTM_SHIPMENT,
(select inv.ATTRIBUTE11 from invoice_shipment invs,invoice inv where 
invs.invoice_gid=inv.invoice_gid and invs.shipment_gid=s.shipment_gid and rownum=1) OTM_INVOICE_AMOUNT_NET,

(select inv.ATTRIBUTE12 from invoice_shipment invs,invoice inv where invs.invoice_gid=inv.invoice_gid and invs.shipment_gid=s.shipment_gid and  rownum=1) 
VAT_AMOUNT,

(select inv.ATTRIBUTE13 from invoice_shipment invs,invoice inv where invs.invoice_gid=inv.invoice_gid and invs.shipment_gid=s.shipment_gid and rownum=1)
OTM_INVOICE_AMOUNT_GROSS,

(select inv.ATTRIBUTE14 from invoice_shipment invs,invoice inv where invs.invoice_gid=inv.invoice_gid and 
invs.shipment_gid=s.shipment_gid and rownum=1) INVOICE_CURRENCY,

(select glog_util.remove_domain(VAT_CODE_GID) from vat_analysis VA, invoice_shipment invs where VA.invoice_gid=invs.invoice_gid and 
invs.shipment_gid = s.shipment_gid and rownum=1) TREATMENT_CODE,

(SELECT SR.SHIPMENT_REFNUM_VALUE FROM SHIPMENT_REFNUM SR where sr.shipment_gid =s.shipment_gid and sr.SHIPMENT_REFNUM_QUAL_GID='LEGO.LLP_RESPONSIBILITY')
FBA_RESPONSIBILITY_STATUS,

(SELECT loc_rem.remark_text FROM  location  l, shipment_involved_party  sip,location_remark    loc_rem
WHERE l.location_gid=sip.involved_party_contact_gid AND loc_rem.location_gid=l.location_gid 
AND sip.involved_party_qual_gid='BILL_TO' AND loc_rem.remark_qual_gid='LEGO.BILL_TO_VAT_NUMBER' AND sip.shipment_gid=s.shipment_gid) BILL_TO_VAT_NUMBER,
(SELECT sr.remark_text FROM shipment_remark sr WHERE sr.remark_qual_gid='LEGO.OTM_CARRIER_VAT_NUMBER' AND sr.shipment_gid=s.shipment_gid) CARRIER_VAT_NUMBER

 
from 
glogowner.invoice inv,
glogowner.invoice_shipment invs,
glogowner.order_Release orl,
glogowner.order_movement om,
glogowner.shipment s
 where 
orl.order_Release_gid=om.order_Release_Gid and  
om.shipment_Gid=s.shipment_Gid and 
inv.invoice_gid(+)=invs.invoice_gid and 
invs.shipment_gid(+)=s.shipment_gid and 
s.shipment_gid in (select inv_s.shipment_gid from invoice inv, invoice_shipment inv_s,order_movement om where
inv.invoice_gid = inv_s.invoice_gid and
invs.shipment_gid=om.shipment_gid
AND inv.attribute2 in ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED') AND
 (:P_FBA_OTM_RESPONSIBILITY in (select  SR.shipment_refnum_value  from shipment_refnum  sr  where 
SR.shipment_refnum_qual_gid='LEGO.LLP_RESPONSIBILITY' and sr.shipment_gid = s.shipment_gid) 
or :P_FBA_OTM_RESPONSIBILITY IS NULL) 
AND (TRUNC(inv.ATTRIBUTE_DATE1) BETWEEN TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT) AND 
TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) AND (TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) - 
TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT)) <= 31))
and om.order_Release_Gid in (select om.order_release_gid from invoice inv, invoice_shipment inv_s,order_movement om where
inv.invoice_gid = inv_s.invoice_gid and
invs.shipment_gid=om.shipment_gid AND
inv.attribute2 in ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED')
AND (TRUNC(inv.ATTRIBUTE_DATE1) BETWEEN TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT) AND 
TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) AND (TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) - 
TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT)) <= 31))
and s.shipment_gid like 'LEGO.%' 
AND  (:P_FBA_OTM_RESPONSIBILITY in (select  SR.shipment_refnum_value  from shipment_refnum  sr  where 
SR.shipment_refnum_qual_gid='LEGO.LLP_RESPONSIBILITY' and sr.shipment_gid = s.shipment_gid) 
or :P_FBA_OTM_RESPONSIBILITY IS NULL) 
and inv.ATTRIBUTE2 in ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED')
and not exists (select 1 from invoice_remark ir, invoice inv  where
ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_SHIPMENT_ID' and ir.REMARK_SEQ_NO=15 and ir.invoice_gid =inv.invoice_gid  and ir.REMARK_TEXT = s.shipment_gid))

UNION 


select OTM_SHIPMENT_NUMBER
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
,BILL_TO_LEGAL_NAME 
,EQUIPMENT_TYPE
,OTM_INVOICE_CURRENCY
,OTM_INVOICE_VALUE
,CARRIER_INVOICE_RECEIPT_DATE
,CARRIER_INVOICE_VALUE_MATCHED
,OTM_SHIPMENT_CURRENCY_GID
,SHIPMENT_TOTAL_ACTUAL_COST
,INVOICE_STATUS_DATE
,round(NVL(SHIPMENT_BASE_COST,0)+NVL(SHIPMENT_ACCESSORIAL_COST,0)+NVL(TOTAL_FUEL_SURCHARGE,0),2) TOTAL_FREIGHT_FUEL
,FBA_PROCESS_MODE
,SHIPMENT_BASE_COST
,SHIPMENT_ACCESSORIAL_COST 
,BILL_TO_ADDRESS
,DOP_CONSIGNMENT_NUMBER
,TOTAL_FUEL_SURCHARGE
,OTM_COST_OK_DATE
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

with temp as(select shipment_Gid, order_Release_gid,leg,description,sum(cost)cost from(
select 
s.shipment_Gid
,om.order_Release_gid
,case when sr.shipment_refnum_value in('DIRECT','NO_VALUE') then 'LEG2' else sr.shipment_refnum_value end leg
,(case  
when aord.ACCESSORIAL_CODE_GID in
('LEGO.DEMURRAGE',
'LEGO.WAITING_TIME',
'LEGO.WAITING_TIME_CHARGE_PER_HR')
 then
  'COST4'
when aord.ACCESSORIAL_CODE_GID in 
('LEGO.CANCELLATION',
'LEGO.CANCELLATION_PERCENT',
'LEGO.REFUSAL',
'LEGO.REFUSAL_AS_PERCENTAGE_OF_DELIVERY')
 then
  'COST5'
/* ************ LEG 1 ************ */
when sr.shipment_refnum_value='LEG1' and  aord.cost_description= 'B' then
'COST1'
when (sr.shipment_refnum_value='LEG1' and aord.cost_description ='A' and  aord.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when (sr.shipment_refnum_value='LEG1' and aord.cost_description ='A' and  aord.ACCESSORIAL_CODE_GID IN 
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
when sr.shipment_refnum_value  in('LEG2','DIRECT','NO_VALUE') and  aord.cost_description= 'B' then
'COST1'
when (sr.shipment_refnum_value  in('LEG2','DIRECT','NO_VALUE') and aord.cost_description ='A' and  aord.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when (sr.shipment_refnum_value in('LEG2','DIRECT','NO_VALUE') and  (aord.cost_description='S' or  aord.ACCESSORIAL_CODE_GID in
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
when sr.shipment_refnum_value ='LEG3'  and  aord.cost_description= 'B' then
'COST1'
when (sr.shipment_refnum_value ='LEG3'  and aord.cost_description ='A' and  aord.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when sr.shipment_refnum_value='LEG3' and   aord.ACCESSORIAL_CODE_GID in 
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


,case when ab.invoice_gid is null then 
(aord.cost*(select cer.exchange_rate from glogowner.currency_exchange_rate cer where 
   cer.effective_date=(select max(cer2.effective_date) from glogowner.currency_exchange_rate cer2 where  
   cer2.effective_date<=s.start_time and
   cer2.from_currency_gid=aord.cost_currency_gid and 
   cer2.to_currency_gid=s.T_ACTUAL_COST_CURRENCY_GID and
   cer2.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' ) and 	
   cer.from_currency_gid=aord.cost_currency_gid and 
   cer.to_currency_gid=s.T_ACTUAL_COST_CURRENCY_GID and
   cer.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' and rownum=1)) 
else
-1*(aord.cost*(select cer.exchange_rate from glogowner.currency_exchange_rate cer where 
   cer.effective_date=(select max(cer2.effective_date) from glogowner.currency_exchange_rate cer2 where  
   cer2.effective_date<=s.start_time and
   cer2.from_currency_gid=aord.cost_currency_gid and 
   cer2.to_currency_gid=s.T_ACTUAL_COST_CURRENCY_GID and
   cer2.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' ) and 	
   cer.from_currency_gid=aord.cost_currency_gid and 
   cer.to_currency_gid=s.T_ACTUAL_COST_CURRENCY_GID and
   cer.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' and rownum=1)) 
end cost

From 
glogowner.ALLOCATION_BASE ab,
glogowner.allocation_order_release_d aord,
glogowner.order_movement om,
glogowner.shipment_Refnum sr,
glogowner.shipment s
where 
ab.alloc_seq_no=aord.alloc_seq_no and 
aord.order_release_gid=om.order_release_gid and 
om.shipment_Gid=s.shipment_Gid and 
sr.shipment_refnum_qual_gid='LEGO.LEG' and
sr.shipment_gid=s.shipment_gid and 
s.shipment_Gid =S.SHIPMENT_GID
and om.order_release_gid = om.order_release_Gid
) group by shipment_Gid,order_Release_gid, leg, description)


/* ********* Main query *********** */
select 
s.shipment_gid
,s.shipment_xid OTM_Shipment_Number
,replace(orl.ORDER_RELEASE_TYPE_GID,'LEGO.')  Order_Type
 ,orl.order_Release_xid Order_Release_ID
,(round(orl.TOTAL_WEIGHT,2) || ' ' || orl.TOTAL_WEIGHT_UOM_CODE) Gross_Weight
,(select listagg((round(orl.TOTAL_NET_WEIGHT,2) || ' ' || orl.TOTAL_NET_WEIGHT_UOM_CODE),',') within group (order by 1)from order_Release orl, order_movement om where orl.order_Release_Gid=om.order_Release_gid and 
om.shipment_Gid=s.shipment_gid and om.SHIPMENT_GID=s.shipment_gid) Actual_Chargeable_Weight
,s.CHARGEABLE_WEIGHT
,s.CHARGEABLE_WEIGHT_UOM_CODE
,NVL((TO_CHAR(TO_DATE((S.ATTRIBUTE3),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')),TO_CHAR(UTC.GET_LOCAL_DATE(S.START_TIME,S.SOURCE_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))AS SHIPMENT_COLLECTION_DATE
,NVL((TO_CHAR(TO_DATE((S.ATTRIBUTE4),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')),TO_CHAR(UTC.GET_LOCAL_DATE(S.END_TIME,S.DEST_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))AS SHIPMENT_DELIVERY_DATE
,replace(s.RATE_GEO_GID,'LEGO.')Lane_id
,(SELECT to_char(rg.EFFECTIVE_DATE,'DD/MM/YYYY hh24:mi:ss') FROM glogowner.rate_geo rg where rg.RATE_GEO_GID=s.RATE_GEO_GID) Rates_Effective_From
,(SELECT to_char(rg.EXPIRATION_DATE,'DD/MM/YYYY hh24:mi:ss') FROM glogowner.rate_geo rg where rg.RATE_GEO_GID=s.RATE_GEO_GID) Rates_Effective_to
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
,(select l.location_name from glogowner.location l where l.location_gid = s.servprov_gid)Carrier_Name
,(select listagg(l.ADDRESS_LINE,', ') within group (order by 1) from location_address l where l.location_gid = s.servprov_gid) CARRIER_ADDRESS
,replace(s.SERVPROV_GID,'LEGO.') CARRIER_OTM_ID
,(select l.COUNTRY_CODE3_GID from glogowner.location l where l.location_gid = s.servprov_gid)Carrier_country
,inv.invoice_xid||DECODE(inv.CONSOLIDATION_TYPE,'CHILD',', '||replace(inv.PARENT_INVOICE_GID,'LEGO.'))  OTM_Invoice_ID	
,inv.invoice_number Carrier_Invoice_Number
,to_char(inv.invoice_date,'DD/MM/YYYY hh24:mi:ss')Carrier_Invoice_Date
,round(inv.NET_AMOUNT_DUE,2) OTM_INVOICE_VALUE
,inv.NET_AMOUNT_DUE_GID OTM_INVOICE_CURRENCY
,case when (select sr.shipment_Refnum_value From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid)='MANUAL' THEN
    to_char(inv.ATTRIBUTE_DATE4,'DD/MM/YYYY HH24:MI:SS')
else
(select TO_CHAR(TO_DATE((IR.REMARK_TEXT),'YYYYMMDD'),'DD/MM/YYYY HH24:MI:SS') from glogowner.invoice_remark ir where 
ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_INVOICE_RECEIPT_DATE' and ir.invoice_gid=inv.invoice_gid )
end  CARRIER_INVOICE_RECEIPT_DATE
,case when (select sr.shipment_Refnum_value From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid)='MANUAL' THEN
    inv.Attribute11 || ' ' ||  inv.Attribute14
else
(select remark_text from glogowner.invoice_remark ir where 
ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_TOTAL_COST_WITH_VAT' and ir.invoice_gid=inv.invoice_gid) 
end CARRIER_INVOICE_VALUE_MATCHED
,s.CURRENCY_GID  OTM_SHIPMENT_CURRENCY_GID
,ROUND(s.TOTAL_ACTUAL_COST,2)  SHIPMENT_TOTAL_ACTUAL_COST
,(select to_char(i_s.update_date,'DD/MM/YYYY hh24:mi:ss') from invoice_status i_s where i_s.status_type_gid = 'LEGO.APPROVAL' and i_s.invoice_gid = inv.invoice_gid) INVOICE_STATUS_DATE 
,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='B'  AND sc.shipment_gid=S.SHIPMENT_GID
) SHIPMENT_BASE_COST
,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='A'  AND sc.shipment_gid=S.SHIPMENT_GID
) SHIPMENT_ACCESSORIAL_COST 
 ,(select  listagg(sr.shipment_Refnum_value,',') within group (order by 1) From GLOGOWNER.shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid)FBA_PROCESS_MODE 
,(SELECT l.location_name FROM location                 l, shipment_involved_party  sip
 WHERE   l.location_gid=sip.involved_party_contact_gid AND sip.involved_party_qual_gid='BILL_TO'
 AND sip.shipment_gid= s.shipment_gid) BILL_TO_LEGAL_NAME 
 ,(SELECT (SELECT  LISTAGG(la.address_line, '::') WITHIN GROUP(ORDER BY la.line_sequence) FROM location_address la WHERE
la.location_gid=l.location_gid)||'::'||l.city||'::'||l.postal_code||'::'||l.country_code3_gid  FROM location l,shipment_involved_party  sip
WHERE l.location_gid=sip.involved_party_contact_gid  AND sip.involved_party_qual_gid='BILL_TO' AND sip.shipment_gid= s.shipment_gid
)BILL_TO_ADDRESS 
,(select  listagg(orr.order_Release_refnum_value,',') within group (order by 1)  from glogowner.order_Release_refnum  orr,glogowner.order_movement om  where 
orr.order_Release_Refnum_qual_gid in('LEGO.ORDER_NUMBER') and  
orr.order_Release_gid=om.order_Release_gid and om.shipment_gid=s.shipment_gid and orr.order_release_gid = om.order_release_Gid) DOP_CONSIGNMENT_NUMBER
 ,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='A' and sc.ACCESSORIAL_CODE_GID='LEGO.FUEL SURCHARGE' AND sc.shipment_gid=s.shipment_gid) TOTAL_FUEL_SURCHARGE
,TO_CHAR(s.ATTRIBUTE_DATE5,'DD/MM/YYYY HH24:MI:SS')  OTM_COST_OK_DATE
,(select sum(t.cost) from temp t where    t.description='COST4' and t.order_Release_Gid=orl.order_Release_Gid and orl.order_Release_Gid = om.order_release_Gid)Delays_total 
,(select sum(t.cost) from temp t where    t.description='COST5' and t.order_Release_Gid=orl.order_Release_Gid and orl.order_Release_Gid = om.order_release_Gid)Cancellation_charge 
,(select sum(t.cost) from temp t where    t.description='OTHERS' and t.order_Release_Gid=orl.order_Release_Gid and orl.order_Release_Gid = om.order_release_Gid)Miscellaneous 
,(SELECT round(SHIPMENT_REFNUM_VALUE,2) FROM  SHIPMENT_REFNUM sr WHERE  sr.SHIPMENT_REFNUM_QUAL_GID='LEGO.EUR_EXCHANGE_RATE' and sr.shipment_gid=s.shipment_GID)PMER_Exchange_rate
,s.attribute1 OTM_Shipment_Status
,CASE WHEN s.ATTRIBUTE_DATE5 IS NOT NULL THEN 
	   'COST OK'
	  else ''
	  end cost_ok
,inv.ATTRIBUTE2 OTM_Invoice_status
,(select  listagg(orr.order_Release_refnum_value,',') within group (order by 1)  from glogowner.order_Release_refnum  orr  where 
orr.order_Release_Refnum_qual_gid='LEGO.SALES_ORG' and  
orr.order_Release_gid=orl.order_Release_gid) Customer_Sales
,(select listagg(round(a.TOTAL_ALLOC_COST,2),',') within group (order by 1) from GLOGOWNER.allocation_base AB,GLOGOWNER.ALLOCATION A where AB.ALLOC_TYPE_QUAL_GID='PLANNING' and AB.shipment_gid=s.shipment_gid
AND A.SHIPMENT_GID=AB.SHIPMENT_GID AND A.ALLOC_SEQ_NO=AB.ALLOC_SEQ_NO AND A.ORDER_RELEASE_GID= om.order_release_Gid)APPORTIONED_OTM_SHIPMENT	 ,

(select inv.ATTRIBUTE11 from invoice_remark invs,invoice inv where 
invs.invoice_gid=inv.invoice_gid 
and invs.remark_qual_identifier = 'LEGO.CELATON_SHIPMENT_ID'
and invs.REMARK_SEQ_NO = 15
and invs.remark_text=s.shipment_gid and rownum=1) OTM_INVOICE_AMOUNT_NET,

(select inv.ATTRIBUTE12 from invoice_remark invs,invoice inv where 
invs.invoice_gid=inv.invoice_gid 
and invs.remark_qual_identifier = 'LEGO.CELATON_SHIPMENT_ID'
and invs.REMARK_SEQ_NO = 15
and invs.remark_text=s.shipment_gid and rownum=1) 
VAT_AMOUNT,

(select inv.ATTRIBUTE13 from invoice_remark invs,invoice inv where 
invs.invoice_gid=inv.invoice_gid 
and invs.remark_qual_identifier = 'LEGO.CELATON_SHIPMENT_ID'
and invs.REMARK_SEQ_NO = 15
and invs.remark_text=s.shipment_gid and rownum=1)
OTM_INVOICE_AMOUNT_GROSS,

(select inv.ATTRIBUTE14 from invoice_remark invs,invoice inv where 
invs.invoice_gid=inv.invoice_gid 
and invs.remark_qual_identifier = 'LEGO.CELATON_SHIPMENT_ID'
and invs.REMARK_SEQ_NO = 15
and invs.remark_text=s.shipment_gid and rownum=1) INVOICE_CURRENCY,

(select glog_util.remove_domain(VAT_CODE_GID) from vat_analysis VA,invoice_remark inv_r where VA.invoice_gid=inv_r.invoice_gid and 
inv_r.remark_qual_identifier = 'LEGO.CELATON_SHIPMENT_ID' AND
inv_r.REMARK_SEQ_NO = 15 AND
inv_r.remark_text =S.SHIPMENT_GID AND ROWNUM=1)TREATMENT_CODE,

(SELECT SR.SHIPMENT_REFNUM_VALUE FROM SHIPMENT_REFNUM SR where sr.shipment_gid =s.shipment_gid and sr.SHIPMENT_REFNUM_QUAL_GID='LEGO.LLP_RESPONSIBILITY')
FBA_RESPONSIBILITY_STATUS,

(SELECT loc_rem.remark_text FROM  location  l, shipment_involved_party  sip,location_remark    loc_rem
WHERE l.location_gid=sip.involved_party_contact_gid AND loc_rem.location_gid=l.location_gid 
AND sip.involved_party_qual_gid='BILL_TO' AND loc_rem.remark_qual_gid='LEGO.BILL_TO_VAT_NUMBER' AND sip.shipment_gid=s.shipment_gid) BILL_TO_VAT_NUMBER,
(SELECT sr.remark_text FROM shipment_remark sr WHERE sr.remark_qual_gid='LEGO.OTM_CARRIER_VAT_NUMBER' AND sr.shipment_gid=s.shipment_gid) 
CARRIER_VAT_NUMBER


from 
glogowner.invoice inv,
glogowner.order_Release orl,
glogowner.order_movement om,
glogowner.shipment s,
invoice_remark ir
 where 
orl.order_Release_gid=om.order_Release_Gid and  
om.shipment_Gid=s.shipment_Gid and s.shipment_gid like 'LEGO.%' 
AND  (:P_FBA_OTM_RESPONSIBILITY in (select  SR.shipment_refnum_value  from shipment_refnum  sr  where 
SR.shipment_refnum_qual_gid='LEGO.LLP_RESPONSIBILITY' and sr.shipment_gid = s.shipment_gid) 
or :P_FBA_OTM_RESPONSIBILITY IS NULL) 
 and 
inv.invoice_gid=ir.invoice_gid and 
ir.remark_text=s.shipment_gid and 
s.shipment_gid in (select inv_r.remark_text from invoice inv, invoice_remark inv_r,order_movement om where 
inv.invoice_gid = inv_r.invoice_gid AND
inv_r.remark_text = om.shipment_gid
and inv_r.remark_qual_identifier = 'LEGO.CELATON_SHIPMENT_ID'
and inv_r.REMARK_SEQ_NO = 15 
and inv.attribute2 in ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED') AND
(TRUNC(inv.ATTRIBUTE_DATE1) BETWEEN TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT) AND 
TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) AND (TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) - 
TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT)) <= 31))
and om.order_Release_Gid in(select om.order_release_gid from invoice inv, invoice_remark inv_r,order_movement om where 
inv.invoice_gid = inv_r.invoice_gid AND
inv_r.remark_text = om.shipment_gid
and inv_r.remark_qual_identifier = 'LEGO.CELATON_SHIPMENT_ID'
and inv_r.REMARK_SEQ_NO = 15 
and inv.attribute2 in ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED') AND
(TRUNC(inv.ATTRIBUTE_DATE1) BETWEEN TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT) AND 
TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) AND (TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) - 
TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT)) <= 31))
and ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_SHIPMENT_ID' and ir.REMARK_SEQ_NO=15 
and inv.attribute2  in ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED') AND  (:P_FBA_OTM_RESPONSIBILITY in (select  SR.shipment_refnum_value  from shipment_refnum  sr where 
SR.shipment_refnum_qual_gid='LEGO.LLP_RESPONSIBILITY' and sr.shipment_gid = s.shipment_gid) 
or :P_FBA_OTM_RESPONSIBILITY IS NULL) )

union



select OTM_SHIPMENT_NUMBER
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
,OTM_INVOICE_CURRENCY
,OTM_INVOICE_VALUE
,CARRIER_INVOICE_RECEIPT_DATE
,CARRIER_INVOICE_VALUE_MATCHED
,OTM_SHIPMENT_CURRENCY_GID
,SHIPMENT_TOTAL_ACTUAL_COST
,INVOICE_STATUS_DATE
,round(NVL(SHIPMENT_BASE_COST,0)+NVL(SHIPMENT_ACCESSORIAL_COST,0)+NVL(TOTAL_FUEL_SURCHARGE,0),2) TOTAL_FREIGHT_FUEL
,BILL_TO_LEGAL_NAME 
,FBA_PROCESS_MODE
,SHIPMENT_BASE_COST
,SHIPMENT_ACCESSORIAL_COST 
,BILL_TO_ADDRESS
,DOP_CONSIGNMENT_NUMBER
,TOTAL_FUEL_SURCHARGE
,OTM_COST_OK_DATE
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
/* ********* Main query *********** */
select 
NULL OTM_Shipment_Number
,NULL  Order_Type
 ,NULL Order_Release_ID
,NULL Gross_Weight
,NULL Actual_Chargeable_Weight
,NULL  SHIPMENT_COLLECTION_DATE
,NULL SHIPMENT_DELIVERY_DATE
,NULL Lane_id
,NULL Rates_Effective_From
,NULL Rates_Effective_to
,NULL transport_Mode
,NULL Equipment_Type
,NULL COLLECTION_POINT_NAME
,NULL COLLECTION_POINT_CITY
,NULL COLLECTION_POINT_COUNTRY
,NULL COLLECTION_POINT_ID
,NULL DELIVERY_POINT_NAME
,NULL DELIVERY_POINT_CITY
,NULL DELIVERY_POINT_COUNTRY
,NULL DELIVERY_POINT_ID  
,NULL Carrier_Name
,NULL CARRIER_ADDRESS
,NULL CARRIER_OTM_ID
,NULL Carrier_country
,inv.invoice_xid||DECODE(inv.CONSOLIDATION_TYPE,'CHILD',', '||replace(inv.PARENT_INVOICE_GID,'LEGO.'))  OTM_Invoice_ID	
,inv.invoice_number Carrier_Invoice_Number
,to_char(inv.invoice_date,'DD/MM/YYYY hh24:mi:ss')Carrier_Invoice_Date
,round(inv.NET_AMOUNT_DUE,2) OTM_INVOICE_VALUE
,inv.NET_AMOUNT_DUE_GID OTM_INVOICE_CURRENCY
,(select TO_CHAR(TO_DATE((IR.REMARK_TEXT),'YYYYMMDD'),'DD-MM-YYYY') from glogowner.invoice_remark ir where 
ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_INVOICE_RECEIPT_DATE' and ir.invoice_gid=inv.invoice_gid) CARRIER_INVOICE_RECEIPT_DATE
,NULL CARRIER_INVOICE_VALUE_MATCHED
,NULL OTM_SHIPMENT_CURRENCY_GID
,NULL  SHIPMENT_TOTAL_ACTUAL_COST
,(select to_char(i_s.update_date,'DD/MM/YYYY hh24:mi:ss') from invoice_status i_s where i_s.status_type_gid = 'LEGO.APPROVAL' and i_s.invoice_gid = inv.invoice_gid) INVOICE_STATUS_DATE 
,NULL SHIPMENT_BASE_COST
,NULL SHIPMENT_ACCESSORIAL_COST 
 ,NULL FBA_PROCESS_MODE 
,NULL BILL_TO_LEGAL_NAME 
,NULL BILL_TO_ADDRESS 
,NULL DOP_CONSIGNMENT_NUMBER
 ,NULL TOTAL_FUEL_SURCHARGE
,NULL OTM_COST_OK_DATE
,NULL COST_OK
,NULL Delays_total 
,NULL Cancellation_charge 
,NULL Miscellaneous 
,NULL PMER_Exchange_rate
,NULL OTM_Shipment_Status
, inv.attribute2 OTM_Invoice_status
,NULL Customer_Sales
,NULL APPORTIONED_OTM_SHIPMENT	 
, inv.ATTRIBUTE11 OTM_INVOICE_AMOUNT_NET,
inv.ATTRIBUTE12 VAT_AMOUNT,
 inv.ATTRIBUTE13 OTM_INVOICE_AMOUNT_GROSS,
inv.attribute14 INVOICE_CURRENCY,
NULL TREATMENT_CODE,
NULL FBA_RESPONSIBILITY_STATUS,
NULL BILL_TO_VAT_NUMBER,
NULL CARRIER_VAT_NUMBER
from 
glogowner.invoice inv,
invoice_remark ir
where ir.invoice_gid like 'LEGO.%' and 
not exists(select 1 from invoice_status invst where 
invst.status_value_gid in('LEGO.APPROVAL_APPROVED_AUTO','LEGO.APPROVAL_APPROVED_MANUAL') and 
invst.STATUS_TYPE_GID ='LEGO.APPROVAL' and invst.invoice_gid=inv.invoice_gid) and 
inv.invoice_gid=ir.invoice_gid and inv.attribute2 in  ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED')
AND :P_FBA_OTM_RESPONSIBILITY IS NULL 
AND :P_BILL_TO_LEGAL_NAME IS NULL
and ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_SHIPMENT_ID' and ir.REMARK_SEQ_NO=15
AND not exists (select 'Z' from shipment s where s.shipment_gid = ir.remark_text)
AND (TRUNC(inv.ATTRIBUTE_DATE1) BETWEEN TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT) AND 
TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) AND (TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) - 
TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT)) <= 31)
and not exists (select '1' from invoice_shipment invs where invs.invoice_gid=inv.invoice_gid)
and :P_FBA_OTM_RESPONSIBILITY is null
and :P_BILL_TO_LEGAL_NAME is null
)