select OTM_SHIPMENT_NUMBER
,DOP_CONSIGNMENT_NUMBER
,ORDER_TYPE
,ORDER_RELEASE_ID
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
,GROSS_WEIGHT
,OTM_COST_OK_DATE
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
,round(DELAYS_TOTAL,2)DELAYS_TOTAL
,round(CANCELLATION_CHARGE,2)CANCELLATION_CHARGE
,round(MISCELLANEOUS,2)MISCELLANEOUS
,PMER_EXCHANGE_RATE
,OTM_SHIPMENT_STATUS
,COST_OK
,OTM_INVOICE_STATUS
,CUSTOMER_SALES
,round(NVL(SHIPMENT_BASE_COST,0)+NVL(SHIPMENT_ACCESSORIAL_COST,0)+NVL(TOTAL_FUEL_SURCHARGE,0),2) TOTAL_FREIGHT_FUEL
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
with temp as(select shipment_Gid,invoice_gid,leg,description,sum(cost)cost from(
select 
s.shipment_gid
,inv.invoice_gid
,case when sr.shipment_refnum_value in('DIRECT','NO_VALUE') then 'LEG2' else sr.shipment_refnum_value end leg
,(case  
when il.ACCESSORIAL_CODE_GID in
('LEGO.DEMURRAGE',
'LEGO.WAITING_TIME',
'LEGO.WAITING_TIME_CHARGE_PER_HR')
 then
  'COST4'
when il.ACCESSORIAL_CODE_GID in 
('LEGO.CANCELLATION',
'LEGO.CANCELLATION_PERCENT',
'LEGO.REFUSAL',
'LEGO.REFUSAL_AS_PERCENTAGE_OF_DELIVERY')
 then
  'COST5'
/* ************ LEG 1 ************ */
when sr.shipment_refnum_value='LEG1' and  il.cost_type_gid= 'B' then
'COST1'
when (sr.shipment_refnum_value='LEG1' and il.cost_type_gid ='A' and  il.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when (sr.shipment_refnum_value='LEG1' and il.cost_type_gid ='A' and  il.ACCESSORIAL_CODE_GID IN 
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
'LEGO.FERRY_CHARGE')) then
'COST3'
when sr.shipment_refnum_value='LEG1' then
'OTHERS'
/* ************ LEG 2 ************ */
when sr.shipment_refnum_value  in('LEG2','DIRECT','NO_VALUE') and  il.cost_type_gid= 'B' then
'COST1'
when (sr.shipment_refnum_value  in('LEG2','DIRECT','NO_VALUE') and il.cost_type_gid ='A' and  il.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when (sr.shipment_refnum_value in('LEG2','DIRECT','NO_VALUE') and  (il.cost_type_gid='S' or  il.ACCESSORIAL_CODE_GID in
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
'LEGO.FERRY_CHARGE') )) then
 'COST3'
when sr.shipment_refnum_value in('LEG2','DIRECT','NO_VALUE') then
'OTHERS' 
/* ************ LEG 3 ************ */
when sr.shipment_refnum_value ='LEG3'  and  il.cost_type_gid= 'B' then
'COST1'
when (sr.shipment_refnum_value ='LEG3'  and il.cost_type_gid ='A' and  il.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when sr.shipment_refnum_value='LEG3' and   il.ACCESSORIAL_CODE_GID in 
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
'LEGO.FERRY_CHARGE') then
'COST3'
when sr.shipment_refnum_value='LEG3' then
'OTHERS' 
end)  description

,(il.FREIGHT_CHARGE*(select cer.exchange_rate from currency_exchange_rate cer where 
   cer.effective_date=(select max(cer2.effective_date) from currency_exchange_rate cer2 where  
   cer2.effective_date<=s.start_time and
   cer2.from_currency_gid=il.FREIGHT_CHARGE_GID and 
   cer2.to_currency_gid=inv.CURRENCY_GID and
   cer2.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' ) and 	
   cer.from_currency_gid=il.FREIGHT_CHARGE_GID and 
   cer.to_currency_gid=inv.CURRENCY_GID and
   cer.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' and rownum=1)) cost
from 
shipment_Refnum sr,shipment s,invoice_lineitem il,invoice_shipment invs,invoice inv
where
not exists(select 1 from invoice_status invst where 
invst.status_value_gid in('LEGO.APPROVAL_APPROVED_AUTO','LEGO.APPROVAL_APPROVED_MANUAL') and
invst.STATUS_TYPE_GID ='LEGO.APPROVAL' and invst.invoice_gid=inv.invoice_gid) and 
il.invoice_gid=inv.invoice_gid and 
inv.invoice_gid=invs.invoice_gid and 
invs.shipment_gid=s.shipment_gid and
sr.shipment_refnum_qual_gid='LEGO.LEG' and
sr.shipment_gid=s.shipment_gid and 
s.shipment_Gid=S.SHIPMENT_GID) group by shipment_Gid,invoice_gid, leg, description)
/* ********* Main query *********** */
select 
s.shipment_xid OTM_Shipment_Number
 ,(select  listagg(orr.order_Release_refnum_value,',') within group (order by 1)  from order_Release_refnum  orr,order_movement om  where 
orr.order_Release_Refnum_qual_gid in('LEGO.ORDER_NUMBER') and  
orr.order_Release_gid=om.order_Release_gid and om.shipment_gid=s.shipment_gid) DOP_CONSIGNMENT_NUMBER
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
,(round(s.TOTAL_WEIGHT,2) || ' ' || s.TOTAL_WEIGHT_UOM_CODE) Gross_Weight
,(select listagg((round(orl.TOTAL_NET_WEIGHT,2) || ' ' || orl.TOTAL_NET_WEIGHT_UOM_CODE),',') within group (order by 1)from order_Release orl, order_movement om where orl.order_Release_Gid=om.order_Release_gid and 
om.shipment_Gid=s.shipment_gid and om.SHIPMENT_GID=S.SHIPMENT_GID) Actual_Chargeable_Weight 
,NVL((TO_CHAR(TO_DATE((S.ATTRIBUTE3),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')),TO_CHAR(UTC.GET_LOCAL_DATE(S.START_TIME,S.SOURCE_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))AS SHIPMENT_COLLECTION_DATE
,NVL((TO_CHAR(TO_DATE((S.ATTRIBUTE4),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')),TO_CHAR(UTC.GET_LOCAL_DATE(S.END_TIME,S.DEST_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))AS SHIPMENT_DELIVERY_DATE
,replace(s.RATE_GEO_GID,'LEGO.')Lane_id
,(SELECT to_char(rg.EFFECTIVE_DATE,'DD/MM/YYYY hh24:mi:ss') FROM rate_geo rg where rg.RATE_GEO_GID=s.RATE_GEO_GID) Rates_Effective_From
,(SELECT to_char(rg.EXPIRATION_DATE,'DD/MM/YYYY hh24:mi:ss') FROM rate_geo rg where rg.RATE_GEO_GID=s.RATE_GEO_GID) Rates_Effective_to
,replace(s.transport_mode_gid,'LEGO.')transport_Mode
,replace(s.FIRST_EQUIPMENT_GROUP_GID,'LEGO.') Equipment_Type
,(select l.location_name from location l where l.location_gid=s.source_location_gid) COLLECTION_POINT_NAME
,(select l.city from location l where l.location_gid=s.source_location_gid)COLLECTION_POINT_CITY
,(select l.COUNTRY_CODE3_GID from location l where l.location_gid=s.source_location_gid)COLLECTION_POINT_COUNTRY
,(select l.location_xid from location l where l.location_gid=s.source_location_gid)COLLECTION_POINT_ID
,(select l.location_name from location l where l.location_gid=s.dest_location_gid) DELIVERY_POINT_NAME
,(select l.city from location l where l.location_gid=s.dest_location_gid)DELIVERY_POINT_CITY
,(select l.COUNTRY_CODE3_GID from location l where l.location_gid=s.dest_location_gid)DELIVERY_POINT_COUNTRY
,(select l.location_xid from location l where l.location_gid=s.dest_location_gid)DELIVERY_POINT_ID
,(select l.location_name from location l where l.location_gid = s.servprov_gid)Carrier_Name
,(SELECT (SELECT  LISTAGG(la.address_line, '::') WITHIN GROUP(ORDER BY la.line_sequence) FROM location_address la WHERE la.location_gid=l.location_gid)||'::'||l.city||'::'||l.postal_code||'::'||l.country_code3_gid  FROM location l WHERE l.location_gid=s.servprov_gid)CARRIER_ADDRESS
,replace(s.SERVPROV_GID,'LEGO.') CARRIER_OTM_ID
,(select l.COUNTRY_CODE3_GID from location l where l.location_gid = s.servprov_gid)Carrier_country
,inv.invoice_xid||DECODE(inv.CONSOLIDATION_TYPE,'CHILD',', '||replace(inv.PARENT_INVOICE_GID,'LEGO.'))  OTM_Invoice_ID	
,inv.invoice_number Carrier_Invoice_Number
,to_char(inv.invoice_date,'DD/MM/YYYY hh24:mi:ss')Carrier_Invoice_Date
,round(inv.NET_AMOUNT_DUE,2) OTM_INVOICE_VALUE
,inv.NET_AMOUNT_DUE_GID  OTM_INVOICE_CURRENCY
 ,case when (select sr.shipment_Refnum_value From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid)='MANUAL' THEN
    to_char(inv.ATTRIBUTE_DATE4,'DD/MM/YYYY HH24:MI:SS')
else
(select TO_CHAR(TO_DATE((IR.REMARK_TEXT),'YYYYMMDD'),'DD/MM/YYYY HH24:MI:SS') from glogowner.invoice_remark ir where 
ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_INVOICE_RECEIPT_DATE' and ir.invoice_gid=inv.invoice_gid )
end  CARRIER_INVOICE_RECEIPT_DATE
,case when (select sr.shipment_Refnum_value From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid)='MANUAL' THEN
    inv.Attribute11 
else
(select remark_text from glogowner.invoice_remark ir where 
ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_TOTAL_COST_WITH_VAT' and ir.invoice_gid=inv.invoice_gid) 
end CARRIER_INVOICE_VALUE_MATCHED
,s.CURRENCY_GID  OTM_SHIPMENT_CURRENCY_GID
,round(s.TOTAL_ACTUAL_COST,2)  SHIPMENT_TOTAL_ACTUAL_COST
,(select to_char(i_s.update_date,'DD/MM/YYYY hh24:mi:ss') from invoice_status i_s where i_s.status_type_gid = 'LEGO.APPROVAL' and i_s.invoice_gid = inv.invoice_gid) INVOICE_STATUS_DATE
,TO_CHAR(s.ATTRIBUTE_DATE5,'DD/MM/YYYY HH24:MI:SS')  OTM_COST_OK_DATE
,(SELECT l.location_name FROM location                 l, shipment_involved_party  sip
 WHERE   l.location_gid=sip.involved_party_contact_gid AND sip.involved_party_qual_gid='BILL_TO'
 AND sip.shipment_gid= S.SHIPMENT_GID) BILL_TO_LEGAL_NAME 
,(SELECT (SELECT  LISTAGG(la.address_line, '::') WITHIN GROUP(ORDER BY la.line_sequence) FROM location_address la WHERE
la.location_gid=l.location_gid)||'::'||l.city||'::'||l.postal_code||'::'||l.country_code3_gid  FROM location l,shipment_involved_party  sip
WHERE l.location_gid=sip.involved_party_contact_gid  AND sip.involved_party_qual_gid='BILL_TO' AND sip.shipment_gid= S.SHIPMENT_GID
)BILL_TO_ADDRESS
,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='B'  AND sc.shipment_gid=S.SHIPMENT_GID) SHIPMENT_BASE_COST
,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='A'  AND sc.shipment_gid=S.SHIPMENT_GID) SHIPMENT_ACCESSORIAL_COST 
,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='A' and sc.ACCESSORIAL_CODE_GID='LEGO.FUEL SURCHARGE' AND sc.shipment_gid=S.SHIPMENT_GID) TOTAL_FUEL_SURCHARGE
 ,(select  listagg(sr.shipment_Refnum_value,',') within group (order by 1) From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid) FBA_PROCESS_MODE
,(select sum(t.cost) from temp t where    t.description='COST4' and t.shipment_gid=s.shipment_Gid and t.invoice_gid=inv.invoice_gid)Delays_total 
,(select sum(t.cost) from temp t where    t.description='COST5' and t.shipment_gid=s.shipment_Gid and t.invoice_gid=inv.invoice_gid)Cancellation_charge 
,(select sum(t.cost) from temp t where    t.description='OTHERS' and t.shipment_gid=s.shipment_Gid and t.invoice_gid=inv.invoice_gid)Miscellaneous 
,(SELECT round(SHIPMENT_REFNUM_VALUE,2) FROM  SHIPMENT_REFNUM sr WHERE  sr.SHIPMENT_REFNUM_QUAL_GID='LEGO.EUR_EXCHANGE_RATE' and sr.shipment_gid=s.shipment_GID)PMER_Exchange_rate
,s.attribute1 OTM_Shipment_Status
,CASE WHEN s.ATTRIBUTE_DATE5 IS NOT NULL THEN 
	   'COST OK'
	  else ''
	  end cost_ok
,inv.ATTRIBUTE2 OTM_Invoice_status
,(select  listagg(orr.order_Release_refnum_value,',') within group (order by 1)  from order_Release_refnum  orr,order_movement om  where 
orr.order_Release_Refnum_qual_gid='LEGO.SALES_ORG' and  
orr.order_Release_gid=om.order_Release_gid and om.shipment_gid=s.shipment_gid) Customer_Sales
,(select listagg(round(a.TOTAL_ALLOC_COST,2),',') within group (order by 1) from GLOGOWNER.allocation_base AB,GLOGOWNER.ALLOCATION A where AB.ALLOC_TYPE_QUAL_GID='PLANNING' and AB.shipment_gid=S.SHIPMENT_GID
AND A.SHIPMENT_GID=AB.SHIPMENT_GID AND A.ALLOC_SEQ_NO=AB.ALLOC_SEQ_NO)APPORTIONED_OTM_SHIPMENT,
inv.ATTRIBUTE11 OTM_INVOICE_AMOUNT_NET,
inv.ATTRIBUTE12 VAT_AMOUNT,
inv.ATTRIBUTE13 OTM_INVOICE_AMOUNT_GROSS,
 inv.ATTRIBUTE14 INVOICE_CURRENCY,
(select glog_util.remove_domain(VAT_CODE_GID) from vat_analysis VA, invoice_shipment invs where VA.invoice_gid=invs.invoice_gid and 
invs.shipment_gid = S.SHIPMENT_GID and rownum=1) TREATMENT_CODE,

(SELECT SR.SHIPMENT_REFNUM_VALUE FROM SHIPMENT_REFNUM SR where sr.shipment_gid =S.SHIPMENT_GID and sr.SHIPMENT_REFNUM_QUAL_GID='LEGO.LLP_RESPONSIBILITY')
FBA_RESPONSIBILITY_STATUS,

(SELECT loc_rem.remark_text FROM  location  l, shipment_involved_party  sip,location_remark    loc_rem
WHERE l.location_gid=sip.involved_party_contact_gid AND loc_rem.location_gid=l.location_gid 
AND sip.involved_party_qual_gid='BILL_TO' AND loc_rem.remark_qual_gid='LEGO.BILL_TO_VAT_NUMBER' AND sip.shipment_gid=S.SHIPMENT_GID) BILL_TO_VAT_NUMBER,
(SELECT sr.remark_text FROM shipment_remark sr WHERE sr.remark_qual_gid='LEGO.OTM_CARRIER_VAT_NUMBER' AND sr.shipment_gid=S.SHIPMENT_GID) CARRIER_VAT_NUMBER

from 
invoice inv,
invoice_shipment invs,
shipment s,shipment_involved_party shinv
where 
s.shipment_gid like 'LEGO.%' 
and inv.attribute2 in ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED')  
AND  (:P_FBA_OTM_RESPONSIBILITY in (select  SR.shipment_refnum_value  from shipment_refnum  sr where 
SR.shipment_refnum_qual_gid='LEGO.LLP_RESPONSIBILITY' and sr.shipment_gid = s.shipment_gid) 
or :P_FBA_OTM_RESPONSIBILITY IS NULL) AND
inv.invoice_gid(+)=invs.invoice_gid and 
invs.shipment_gid(+)=s.shipment_gid and 
s.shipment_gid = shinv.shipment_gid and
((shinv.INVOLVED_PARTY_CONTACT_GID = :P_BILL_TO_LEGAL_NAME) or :P_BILL_TO_LEGAL_NAME IS NULL) and
s.shipment_gid in 
(select inv_s.shipment_gid from invoice inv, invoice_shipment inv_s where
inv.invoice_gid = inv_s.invoice_gid and
inv.attribute2 in ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED')
AND (TRUNC(inv.ATTRIBUTE_DATE1) BETWEEN TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT) AND 
TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) AND (TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) - 
TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT)) <= 31)
))
UNION 
select OTM_SHIPMENT_NUMBER
,DOP_CONSIGNMENT_NUMBER
,ORDER_TYPE
,ORDER_RELEASE_ID
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
,GROSS_WEIGHT
,OTM_COST_OK_DATE
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
,round(DELAYS_TOTAL,2)DELAYS_TOTAL
,round(CANCELLATION_CHARGE,2)CANCELLATION_CHARGE
,round(MISCELLANEOUS,2)MISCELLANEOUS
,PMER_EXCHANGE_RATE
,OTM_SHIPMENT_STATUS
,COST_OK
,OTM_INVOICE_STATUS
,CUSTOMER_SALES
,round(NVL(SHIPMENT_BASE_COST,0)+NVL(SHIPMENT_ACCESSORIAL_COST,0)+NVL(TOTAL_FUEL_SURCHARGE,0),2) TOTAL_FREIGHT_FUEL
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

with temp as(select shipment_Gid,invoice_gid,leg,description,sum(cost)cost from(
select 
s.shipment_gid
,inv.invoice_gid
,case when sr.shipment_refnum_value in('DIRECT','NO_VALUE') then 'LEG2' else sr.shipment_refnum_value end leg
,(case  
when il.ACCESSORIAL_CODE_GID in
('LEGO.DEMURRAGE',
'LEGO.WAITING_TIME',
'LEGO.WAITING_TIME_CHARGE_PER_HR')
 then
  'COST4'
when il.ACCESSORIAL_CODE_GID in 
('LEGO.CANCELLATION',
'LEGO.CANCELLATION_PERCENT',
'LEGO.REFUSAL',
'LEGO.REFUSAL_AS_PERCENTAGE_OF_DELIVERY')
 then
  'COST5'
/* ************ LEG 1 ************ */
when sr.shipment_refnum_value='LEG1' and  il.cost_type_gid= 'B' then
'COST1'
when (sr.shipment_refnum_value='LEG1' and il.cost_type_gid ='A' and  il.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when (sr.shipment_refnum_value='LEG1' and il.cost_type_gid ='A' and  il.ACCESSORIAL_CODE_GID IN 
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
'LEGO.FERRY_CHARGE')) then
'COST3'
when sr.shipment_refnum_value='LEG1' then
'OTHERS'
/* ************ LEG 2 ************ */
when sr.shipment_refnum_value  in('LEG2','DIRECT','NO_VALUE') and  il.cost_type_gid= 'B' then
'COST1'
when (sr.shipment_refnum_value  in('LEG2','DIRECT','NO_VALUE') and il.cost_type_gid ='A' and  il.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when (sr.shipment_refnum_value in('LEG2','DIRECT','NO_VALUE') and  (il.cost_type_gid='S' or  il.ACCESSORIAL_CODE_GID in
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
'LEGO.FERRY_CHARGE') )) then
 'COST3'
when sr.shipment_refnum_value in('LEG2','DIRECT','NO_VALUE') then
'OTHERS' 
/* ************ LEG 3 ************ */
when sr.shipment_refnum_value ='LEG3'  and  il.cost_type_gid= 'B' then
'COST1'
when (sr.shipment_refnum_value ='LEG3'  and il.cost_type_gid ='A' and  il.ACCESSORIAL_CODE_GID like 'LEGO.%FUEL%') then
'COST2'
when sr.shipment_refnum_value='LEG3' and   il.ACCESSORIAL_CODE_GID in 
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
'LEGO.FERRY_CHARGE') then
'COST3'
when sr.shipment_refnum_value='LEG3' then
'OTHERS' 
end)  description

,(il.FREIGHT_CHARGE*(select cer.exchange_rate from currency_exchange_rate cer where 
   cer.effective_date=(select max(cer2.effective_date) from currency_exchange_rate cer2 where  
   cer2.effective_date<=s.start_time and
   cer2.from_currency_gid=il.FREIGHT_CHARGE_GID and 
   cer2.to_currency_gid=inv.CURRENCY_GID and
   cer2.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' ) and 	
   cer.from_currency_gid=il.FREIGHT_CHARGE_GID and 
   cer.to_currency_gid=inv.CURRENCY_GID and
   cer.exchange_rate_gid='LEGO.DHL_LLP_EXCH_RATE' and rownum=1)) cost
from 
shipment_Refnum sr,shipment s,invoice_lineitem il,invoice_shipment invs,invoice inv
where
not exists(select 1 from invoice_status invst where 
invst.status_value_gid in('LEGO.APPROVAL_APPROVED_AUTO','LEGO.APPROVAL_APPROVED_MANUAL') and
invst.STATUS_TYPE_GID ='LEGO.APPROVAL' and invst.invoice_gid=inv.invoice_gid) and 
il.invoice_gid=inv.invoice_gid and 
inv.invoice_gid=invs.invoice_gid and 
invs.shipment_gid=s.shipment_gid and
sr.shipment_refnum_qual_gid='LEGO.LEG' and
sr.shipment_gid=s.shipment_gid and 
s.shipment_Gid=S.SHIPMENT_GID) group by shipment_Gid,invoice_gid, leg, description)
/* ********* Main query *********** */
select 
s.shipment_xid OTM_Shipment_Number
 ,(select  listagg(orr.order_Release_refnum_value,',') within group (order by 1)  from order_Release_refnum  orr,order_movement om  where 
orr.order_Release_Refnum_qual_gid in('LEGO.ORDER_NUMBER') and  
orr.order_Release_gid=om.order_Release_gid and om.shipment_gid=s.shipment_gid) DOP_CONSIGNMENT_NUMBER
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

,(round(s.TOTAL_WEIGHT,2) || ' ' || s.TOTAL_WEIGHT_UOM_CODE) Gross_Weight
,(select listagg((round(orl.TOTAL_NET_WEIGHT,2) || ' ' || orl.TOTAL_NET_WEIGHT_UOM_CODE),',') within group (order by 1)from order_Release orl, order_movement om where orl.order_Release_Gid=om.order_Release_gid and 
om.shipment_Gid=s.shipment_gid and om.SHIPMENT_GID=S.SHIPMENT_GID) Actual_Chargeable_Weight 
,NVL((TO_CHAR(TO_DATE((S.ATTRIBUTE3),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')),TO_CHAR(UTC.GET_LOCAL_DATE(S.START_TIME,S.SOURCE_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))AS SHIPMENT_COLLECTION_DATE
,NVL((TO_CHAR(TO_DATE((S.ATTRIBUTE4),'YYYY-MM-DD HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')),TO_CHAR(UTC.GET_LOCAL_DATE(S.END_TIME,S.DEST_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))AS SHIPMENT_DELIVERY_DATE
,replace(s.RATE_GEO_GID,'LEGO.')Lane_id
,(SELECT to_char(rg.EFFECTIVE_DATE,'DD/MM/YYYY hh24:mi:ss') FROM rate_geo rg where rg.RATE_GEO_GID=s.RATE_GEO_GID) Rates_Effective_From
,(SELECT to_char(rg.EXPIRATION_DATE,'DD/MM/YYYY hh24:mi:ss') FROM rate_geo rg where rg.RATE_GEO_GID=s.RATE_GEO_GID) Rates_Effective_to
,replace(s.transport_mode_gid,'LEGO.')transport_Mode
,replace(s.FIRST_EQUIPMENT_GROUP_GID,'LEGO.') Equipment_Type
,(select l.location_name from location l where l.location_gid=s.source_location_gid) COLLECTION_POINT_NAME
,(select l.city from location l where l.location_gid=s.source_location_gid)COLLECTION_POINT_CITY
,(select l.COUNTRY_CODE3_GID from location l where l.location_gid=s.source_location_gid)COLLECTION_POINT_COUNTRY
,(select l.location_xid from location l where l.location_gid=s.source_location_gid)COLLECTION_POINT_ID
,(select l.location_name from location l where l.location_gid=s.dest_location_gid) DELIVERY_POINT_NAME
,(select l.city from location l where l.location_gid=s.dest_location_gid)DELIVERY_POINT_CITY
,(select l.COUNTRY_CODE3_GID from location l where l.location_gid=s.dest_location_gid)DELIVERY_POINT_COUNTRY
,(select l.location_xid from location l where l.location_gid=s.dest_location_gid)DELIVERY_POINT_ID
,(select l.location_name from location l where l.location_gid = s.servprov_gid)Carrier_Name
,(SELECT (SELECT  LISTAGG(la.address_line, '::') WITHIN GROUP(ORDER BY la.line_sequence) FROM location_address la WHERE la.location_gid=l.location_gid)||'::'||l.city||'::'||l.postal_code||'::'||l.country_code3_gid  FROM location l WHERE l.location_gid=s.servprov_gid)CARRIER_ADDRESS
,replace(s.SERVPROV_GID,'LEGO.') CARRIER_OTM_ID
,(select l.COUNTRY_CODE3_GID from location l where l.location_gid = s.servprov_gid)Carrier_country
,inv.invoice_xid||DECODE(inv.CONSOLIDATION_TYPE,'CHILD',', '||replace(inv.PARENT_INVOICE_GID,'LEGO.'))  OTM_Invoice_ID	
,inv.invoice_number Carrier_Invoice_Number
,to_char(inv.invoice_date,'DD/MM/YYYY hh24:mi:ss')Carrier_Invoice_Date
,round(inv.NET_AMOUNT_DUE,2) OTM_INVOICE_VALUE
,inv.NET_AMOUNT_DUE_GID  OTM_INVOICE_CURRENCY
 ,case when (select sr.shipment_Refnum_value From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid)='MANUAL' THEN
    to_char(inv.ATTRIBUTE_DATE4,'DD/MM/YYYY HH24:MI:SS')
else
(select TO_CHAR(TO_DATE((IR.REMARK_TEXT),'YYYYMMDD'),'DD/MM/YYYY HH24:MI:SS') from glogowner.invoice_remark ir where 
ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_INVOICE_RECEIPT_DATE' and ir.invoice_gid=inv.invoice_gid )
end  CARRIER_INVOICE_RECEIPT_DATE
,case when (select sr.shipment_Refnum_value From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid)='MANUAL' THEN
    inv.Attribute11 
else
(select remark_text from glogowner.invoice_remark ir where 
ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_TOTAL_COST_WITH_VAT' and ir.invoice_gid=inv.invoice_gid) 
end CARRIER_INVOICE_VALUE_MATCHED
,s.CURRENCY_GID  OTM_SHIPMENT_CURRENCY_GID
,round(s.TOTAL_ACTUAL_COST,2)  SHIPMENT_TOTAL_ACTUAL_COST
,(select to_char(i_s.update_date,'DD/MM/YYYY hh24:mi:ss') from invoice_status i_s where i_s.status_type_gid = 'LEGO.APPROVAL' and i_s.invoice_gid = inv.invoice_gid) INVOICE_STATUS_DATE
,TO_CHAR(s.ATTRIBUTE_DATE5,'DD/MM/YYYY HH24:MI:SS')  OTM_COST_OK_DATE
,(SELECT l.location_name FROM location                 l, shipment_involved_party  sip
 WHERE   l.location_gid=sip.involved_party_contact_gid AND sip.involved_party_qual_gid='BILL_TO'
 AND sip.shipment_gid= S.SHIPMENT_GID) BILL_TO_LEGAL_NAME 
,(SELECT (SELECT  LISTAGG(la.address_line, '::') WITHIN GROUP(ORDER BY la.line_sequence) FROM location_address la WHERE
la.location_gid=l.location_gid)||'::'||l.city||'::'||l.postal_code||'::'||l.country_code3_gid  FROM location l,shipment_involved_party  sip
WHERE l.location_gid=sip.involved_party_contact_gid  AND sip.involved_party_qual_gid='BILL_TO' AND sip.shipment_gid= S.SHIPMENT_GID
)BILL_TO_ADDRESS
,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='B'  AND sc.shipment_gid=S.SHIPMENT_GID) SHIPMENT_BASE_COST
,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='A'  AND sc.shipment_gid=S.SHIPMENT_GID) SHIPMENT_ACCESSORIAL_COST 
,(select round(sum(sc.cost),2) from glogowner.shipment_cost sc,glogowner.shipment invs where sc.shipment_gid=invs.shipment_gid
and sc.cost_type='A' and sc.ACCESSORIAL_CODE_GID='LEGO.FUEL SURCHARGE' AND sc.shipment_gid=S.SHIPMENT_GID) TOTAL_FUEL_SURCHARGE
 ,(select  listagg(sr.shipment_Refnum_value,',') within group (order by 1) From shipment_Refnum sr 
where sr.shipment_Refnum_qual_gid in('LEGO.FBA_PROCESS_MODE')  AND  sr.shipment_gid=s.shipment_gid) FBA_PROCESS_MODE
,(select sum(t.cost) from temp t where    t.description='COST4' and t.shipment_gid=s.shipment_Gid and t.invoice_gid=inv.invoice_gid)Delays_total 
,(select sum(t.cost) from temp t where    t.description='COST5' and t.shipment_gid=s.shipment_Gid and t.invoice_gid=inv.invoice_gid)Cancellation_charge 
,(select sum(t.cost) from temp t where    t.description='OTHERS' and t.shipment_gid=s.shipment_Gid and t.invoice_gid=inv.invoice_gid)Miscellaneous 
,(SELECT round(SHIPMENT_REFNUM_VALUE,2) FROM  SHIPMENT_REFNUM sr WHERE  sr.SHIPMENT_REFNUM_QUAL_GID='LEGO.EUR_EXCHANGE_RATE' and sr.shipment_gid=s.shipment_GID)PMER_Exchange_rate
,s.attribute1 OTM_Shipment_Status
,CASE WHEN s.ATTRIBUTE_DATE5 IS NOT NULL THEN 
	   'COST OK'
	  else ''
	  end cost_ok
,inv.ATTRIBUTE2 OTM_Invoice_status
,(select  listagg(orr.order_Release_refnum_value,',') within group (order by 1)  from order_Release_refnum  orr,order_movement om  where 
orr.order_Release_Refnum_qual_gid='LEGO.SALES_ORG' and  
orr.order_Release_gid=om.order_Release_gid and om.shipment_gid=s.shipment_gid) Customer_Sales
,(select listagg(round(a.TOTAL_ALLOC_COST,2),',') within group (order by 1) from GLOGOWNER.allocation_base AB,GLOGOWNER.ALLOCATION A where AB.ALLOC_TYPE_QUAL_GID='PLANNING' and AB.shipment_gid=S.SHIPMENT_GID
AND A.SHIPMENT_GID=AB.SHIPMENT_GID AND A.ALLOC_SEQ_NO=AB.ALLOC_SEQ_NO)APPORTIONED_OTM_SHIPMENT,

inv.ATTRIBUTE11 OTM_INVOICE_AMOUNT_NET,
inv.ATTRIBUTE12 VAT_AMOUNT,
inv.ATTRIBUTE13 OTM_INVOICE_AMOUNT_GROSS,
 inv.ATTRIBUTE14 INVOICE_CURRENCY,

(select glog_util.remove_domain(VAT_CODE_GID) from vat_analysis VA,invoice_remark inv_r where VA.invoice_gid=inv_r.invoice_gid and 
inv_r.remark_qual_identifier = 'LEGO.CELATON_SHIPMENT_ID' AND
inv_r.REMARK_SEQ_NO = 15 AND
inv_r.remark_text =S.SHIPMENT_GID AND ROWNUM=1) TREATMENT_CODE,

(SELECT SR.SHIPMENT_REFNUM_VALUE FROM SHIPMENT_REFNUM SR where sr.shipment_gid =S.SHIPMENT_GID and sr.SHIPMENT_REFNUM_QUAL_GID='LEGO.LLP_RESPONSIBILITY')
FBA_RESPONSIBILITY_STATUS,

(SELECT loc_rem.remark_text FROM  location  l, shipment_involved_party  sip,location_remark    loc_rem
WHERE l.location_gid=sip.involved_party_contact_gid AND loc_rem.location_gid=l.location_gid 
AND sip.involved_party_qual_gid='BILL_TO' AND loc_rem.remark_qual_gid='LEGO.BILL_TO_VAT_NUMBER' AND sip.shipment_gid=S.SHIPMENT_GID) BILL_TO_VAT_NUMBER,
(SELECT sr.remark_text FROM shipment_remark sr WHERE sr.remark_qual_gid='LEGO.OTM_CARRIER_VAT_NUMBER' AND sr.shipment_gid=S.SHIPMENT_GID) CARRIER_VAT_NUMBER

from 
invoice inv,
invoice_remark ir,
shipment s,
shipment_involved_party shinv
where s.shipment_gid like 'LEGO.%' and 
inv.invoice_gid=ir.invoice_gid  
and s.shipment_gid = shinv.shipment_gid and
((shinv.INVOLVED_PARTY_CONTACT_GID = :P_BILL_TO_LEGAL_NAME) or :P_BILL_TO_LEGAL_NAME IS NULL)
AND  (:P_FBA_OTM_RESPONSIBILITY in (select  SR.shipment_refnum_value  from shipment_refnum  sr  where 
SR.shipment_refnum_qual_gid='LEGO.LLP_RESPONSIBILITY' and sr.shipment_gid = s.shipment_gid) 
or :P_FBA_OTM_RESPONSIBILITY IS NULL) AND
ir.remark_text=s.shipment_gid and inv.attribute2 in ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED')
and ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_SHIPMENT_ID' and ir.REMARK_SEQ_NO=15 AND
s.shipment_gid in (
select inv_r.remark_text from invoice inv, invoice_remark inv_r where 
inv.invoice_gid = inv_r.invoice_gid 
and inv_r.remark_qual_identifier = 'LEGO.CELATON_SHIPMENT_ID'
and inv_r.REMARK_SEQ_NO = 15 
and inv.attribute2 in ('REJECTED_OPERATIONS','REJECTED_CARRIER','ARCHIVED') AND
(TRUNC(inv.ATTRIBUTE_DATE1) BETWEEN TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT) AND 
TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) AND (TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) - 
TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT)) <= 31))
)


UNION 

select OTM_SHIPMENT_NUMBER
,DOP_CONSIGNMENT_NUMBER
,ORDER_TYPE
,ORDER_RELEASE_ID
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
,GROSS_WEIGHT
,OTM_COST_OK_DATE
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
,round(DELAYS_TOTAL,2)DELAYS_TOTAL
,round(CANCELLATION_CHARGE,2)CANCELLATION_CHARGE
,round(MISCELLANEOUS,2)MISCELLANEOUS
,PMER_EXCHANGE_RATE
,OTM_SHIPMENT_STATUS
,COST_OK
,OTM_INVOICE_STATUS
,CUSTOMER_SALES
,round(NVL(SHIPMENT_BASE_COST,0)+NVL(SHIPMENT_ACCESSORIAL_COST,0)+NVL(TOTAL_FUEL_SURCHARGE,0),2) TOTAL_FREIGHT_FUEL
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
where ir.invoice_gid like 'LEGO.%'  
and inv.invoice_gid=ir.invoice_gid and inv.attribute2 not in ('ARCHIVED_RPA_ERROR') AND
:P_FBA_OTM_RESPONSIBILITY IS NULL AND :P_BILL_TO_LEGAL_NAME IS NULL
and ir.REMARK_QUAL_IDENTIFIER='LEGO.CELATON_SHIPMENT_ID' and ir.REMARK_SEQ_NO=15
AND not exists (select 'Z' from shipment s where s.shipment_gid = ir.remark_text) 
AND (TRUNC(inv.ATTRIBUTE_DATE1) BETWEEN TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT) AND 
TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) AND (TO_DATE(:P_REJ_INV_TO_DATE,:P_DATE_FORMAT) - 
TO_DATE(:P_REJ_INV_FROM_DATE,:P_DATE_FORMAT)) <= 31)
and not exists (select '1' from invoice_shipment invs where invs.invoice_gid=inv.invoice_gid)
and :P_FBA_OTM_RESPONSIBILITY is null
and :P_BILL_TO_LEGAL_NAME is null
)