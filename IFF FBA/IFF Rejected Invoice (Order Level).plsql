--! 04.IFF Rejected Invoice (Order Level) 
-- > Notes
    --   > Accessorial codes can vary between accounts
    --   > Attribute columns need to be validated for each account
    --   > 10 refnum, remark and status columns are used, which can vary between accounts
   
    --   > VARIANCES TO ORDER / SHIPMENT
    --   > Filter_CTE uses INVOICE_GID, SHIPMENT_GID AND ORDER_RELEASE_GID instead of SHIPMENT_GID

  -- ! PARAMETERS
    --  ? INLINE PARAMETERS 
      --       :SHIPMENT_ID  
    --  ? INPUT PARAMETERS
      --       {FBA RESPONSIBILITY STATUS}
      --       {DOMAIN}
      --       {BILL TO LEGAL NAME}
      --       {BUSINESS UNIT}
      --       {REJECTED INVOICE TO DATE}
      --       {REJECTED INVOICE FROM DATE}
      --       {TREATMENT CODE}
      --       {CARRIER NAME}
  -- ! ATTRIBUTES 
    --  ? SHIPMENT 
      --      S.ATTRIBUTE1        -  OTM_SHIPMENT_STATUS
      --      S.ATTRIBUTE_DATE6   -  SHIPMENT_DELIVERY_DATE
      --      S.ATTRIBUTE_DATE10  -  SHIPMENT_COLLECTION_DATE
      --      S.ATTRIBUTE_DATE5   -  OTM_COST_OK_DATE
      --      S.ATTRIBUTE9        -  FBA_RESPONSIBILITY_STATUS
    --  ? INVOICE
      --      INV.ATTRIBUTE11     - OTM_INVOICE_AMOUNT_NET
      --      INV.ATTRIBUTE12     - VAT_AMOUNT
      --      INV.ATTRIBUTE13     - OTM_INVOICE_AMOUNT_GROSS
      --      INV.ATTRIBUTE14     - INVOICE_CURRENCY
      --      INV.ATTRIBUTE2      - OTM_INVOICE_STATUS,

  -- ! REFRENCE NUMBERS / REMARKS
    --  ? SHIPMENT REFNUM
      --      SR.SHIPMENT_REFNUM_QUAL_GID - {DOMAIN}||'.LEG'
      --      SR.SHIPMENT_REFNUM_QUAL_GID - {DOMAIN}||'.EUR_EXCHANGE_RATE'
      --      SR.SHIPMENT_REFNUM_QUAL_GID - {DOMAIN}||'.FBA_PROCESS_MODE'
    --  ? SHIPMENT REMARKS
      --      SR.REMARK_QUAL_GID = {DOMAIN}||'.OTM_CARRIER_VAT_NUMBER'  

    --  ? ORDER RELEASE REFNUM 
      --      ORR.ORDER_RELEASE_REFNUM_QUAL_GID - {DOMAIN}||'.BILLING_ENTITY'
      --      ORR.ORDER_RELEASE_REFNUM_QUAL_GID - {DOMAIN}||'.ORDER_NUMBER'
    --  ? SHIPMENT INVOLVED PARTIES
      --      SIP.INVOLVED_PARTY_QUAL_GID - 'BILL_TO'  
    --  ? LOCATION REMARKS
      --      LOC_REM.REMARK_QUAL_GID - {DOMAIN}||'.BILL_TO_VAT_NUMBER'
    --  ? INVOICE REMARKS
      --     IR.REMARK_QUAL_IDENTIFIER = {DOMAIN}||'.CELATON_TOTAL_COST_WITH_VAT'
      --     IR.REMARK_QUAL_IDENTIFIER = {DOMAIN}||'.CELATON_INVOICE_RECEIPT_DATE'
WITH 
FUNCTION TO_CURRENCY(FROM_CURRENCY VARCHAR2, TO_CURRENCY  VARCHAR2, EXCH_RATE_DATE  DATE, EXCH_RATE_GID VARCHAR2)
  RETURN NUMBER AS NEW_VALUE NUMBER ;
  BEGIN SELECT  
      CASE WHEN FROM_CURRENCY = TO_CURRENCY THEN 1 ELSE
        (SELECT CER.EXCHANGE_RATE FROM GLOGOWNER.CURRENCY_EXCHANGE_RATE CER WHERE CER.EFFECTIVE_DATE= 
              (SELECT MAX(CER2.EFFECTIVE_DATE) FROM GLOGOWNER.CURRENCY_EXCHANGE_RATE CER2  WHERE EXCH_RATE_DATE>=CER2.EFFECTIVE_DATE AND CER2.FROM_CURRENCY_GID = FROM_CURRENCY AND CER2.TO_CURRENCY_GID = TO_CURRENCY AND CER2.EXCHANGE_RATE_GID = EXCH_RATE_GID)  
              AND CER.EXCHANGE_RATE_GID = EXCH_RATE_GID AND CER.FROM_CURRENCY_GID = FROM_CURRENCY AND CER.TO_CURRENCY_GID = TO_CURRENCY) END INTO NEW_VALUE FROM DUAL;
RETURN NEW_VALUE;
END; 
FUNCTION RD(GID VARCHAR2) RETURN VARCHAR2
  IS BEGIN RETURN REPLACE(GID, 'IFF'||'.');
END;
FUNCTION TD(DT TIMESTAMP) RETURN VARCHAR2
  IS BEGIN RETURN TO_CHAR(DT, 'DD/MM/YYYY hh24:mi:ss');
END;
FUNCTION NF(NUM VARCHAR2) RETURN VARCHAR2
  IS BEGIN 
   IF REGEXP_LIKE(NUM, '[^0-9]+')  THEN RETURN NULL;
   ELSE RETURN TO_CHAR(NUM, 'FM999G999G999G990D00');
END IF;
END;
-- Creates a table with both Automatic and Manual invoices to be used in later queries for joins
INV_SHIP_CTE AS
  ( 
    SELECT
    DISTINCT
        OM.SHIPMENT_GID
      , INVS.INVOICE_GID
      , OM.ORDER_RELEASE_GID
    FROM
        GLOGOWNER.INVOICE_SHIPMENT                    INVS
      , GLOGOWNER.ORDER_MOVEMENT                      OM
      , GLOGOWNER.INVOICE                             INV
      , INVOICE_REMARK                                IR
    WHERE
      OM.DOMAIN_NAME                                  = {DOMAIN}
      AND INV.ATTRIBUTE2 (+)                          NOT IN ('ARCHIVED', 'ARCHIVED_RPA_ERROR')
      AND INV.INVOICE_GID (+)                         = INVS.INVOICE_GID
      AND INVS.SHIPMENT_GID (+)                       = OM.SHIPMENT_GID    
      AND IR.REMARK_QUAL_IDENTIFIER (+)               = {DOMAIN}||'.CELATON_SHIPMENT_ID'
      AND IR.REMARK_SEQ_NO (+)                        = 15
      AND OM.SHIPMENT_GID                             = IR.REMARK_TEXT (+) 
      AND IR.REMARK_TEXT                              IS NULL
  UNION        
    SELECT
    DISTINCT
      OM.SHIPMENT_GID
      , IR.INVOICE_GID
      , OM.ORDER_RELEASE_GID
    FROM
        GLOGOWNER.INVOICE_REMARK                      IR
      , GLOGOWNER.ORDER_MOVEMENT                      OM
      , GLOGOWNER.INVOICE                             INV
    WHERE
      OM.SHIPMENT_GID                                 =  IR.REMARK_TEXT
      AND IR.REMARK_QUAL_IDENTIFIER                   = {DOMAIN}|| '.CELATON_SHIPMENT_ID'
      AND IR.REMARK_SEQ_NO                            = 15
      AND INV.INVOICE_GID                             = IR.INVOICE_GID
      AND INV.ATTRIBUTE2                              NOT IN ('ARCHIVED', 'ARCHIVED_RPA_ERROR')
      AND OM.DOMAIN_NAME                              = {DOMAIN}
  ), 
APPR_INVOICE_CTE AS (
  SELECT
      ISCTE.SHIPMENT_GID
    , MAX(INVS.ATTRIBUTE_DATE8)                       INVOICE_APPROVED_DATE
    , MAX(INVS.ATTRIBUTE_DATE1)                       INVOICE_REJECTED_DATE
    , SUM(CASE WHEN INVS.ATTRIBUTE_DATE8 IS NOT NULL THEN INVS.NET_AMOUNT_DUE END)                                                                                                 APPROVED_INVOICE_NET_AMOUNT
  FROM 
      INVOICE                                         INVS
    , INV_SHIP_CTE                                    ISCTE
  WHERE 
      INVS.INVOICE_GID                                = ISCTE.INVOICE_GID
  GROUP BY 
    ISCTE.SHIPMENT_GID
  , INVS.DOMAIN_NAME  
),
SHIP_REFNUM_CTE AS (
  SELECT
      SR.SHIPMENT_GID 
    , MAX(CASE SR.SHIPMENT_REFNUM_QUAL_GID                WHEN SR.DOMAIN_NAME ||'.EUR_EXCHANGE_RATE' THEN TO_CHAR(SHIPMENT_REFNUM_VALUE,'FM9D99999')  END)                         PMER_EXCHANGE_RATE 
    , MAX(CASE SR.SHIPMENT_REFNUM_QUAL_GID                WHEN SR.DOMAIN_NAME ||'.LANE_ID'           THEN SHIPMENT_REFNUM_VALUE END)                                               LANE_ID         
    , LISTAGG(DISTINCT CASE SR.SHIPMENT_REFNUM_QUAL_GID   WHEN SR.DOMAIN_NAME ||'.LLP_RESPONSIBILITY'THEN SHIPMENT_REFNUM_VALUE END)                                               FBA_RESPONSIBILITY_STATUS
    , MAX(CASE SR.SHIPMENT_REFNUM_QUAL_GID                WHEN SR.DOMAIN_NAME ||'.FBA_PROCESS_MODE'  THEN SHIPMENT_REFNUM_VALUE END)                                               FBA_PROCESS_MODE
    , SUM(CASE                                            WHEN SR.SHIPMENT_REFNUM_QUAL_GID LIKE '%TAX_AMOUNT%'THEN SHIPMENT_REFNUM_VALUE END)                                      SHIPMENT_TOTAL_TAX 
    , MAX(CASE SR.SHIPMENT_REFNUM_QUAL_GID                WHEN SR.DOMAIN_NAME ||'.OTM_CURRENCY'      THEN SHIPMENT_REFNUM_VALUE END)                                               OTM_CURRENCY
  FROM 
    GLOGOWNER.SHIPMENT_REFNUM                         SR 
  WHERE 
    DOMAIN_NAME                                       = {DOMAIN} 
  GROUP BY 
    SR.SHIPMENT_GID
), 
SHIP_COST_CTE AS (
  SELECT
      SC.SHIPMENT_GID
    , (SC.COST / TO_CURRENCY('EUR' , sc.COST_GID, SC.EXCHANGE_RATE_DATE, SC.EXCHANGE_RATE_GID))*TO_CURRENCY( 'EUR', SR.OTM_CURRENCY , SC.EXCHANGE_RATE_DATE, SC.EXCHANGE_RATE_GID) COST
    , SC.INSERT_DATE                                  INSERT_DATE
    , SC.DOMAIN_NAME
    , SC.COST_TYPE
    , SC.ACCESSORIAL_CODE_GID
    , AICTE.INVOICE_APPROVED_DATE
    , AICTE.INVOICE_REJECTED_DATE
    , AICTE.APPROVED_INVOICE_NET_AMOUNT
    , S.TRANSPORT_MODE_GID
  FROM 
      GLOGOWNER.SHIPMENT_COST                         SC 
    , GLOGOWNER.SHIPMENT                              S
    , APPR_INVOICE_CTE                                AICTE
    , SHIP_REFNUM_CTE                                 SR
  WHERE 
    SC.SHIPMENT_GID                                   = S.SHIPMENT_GID  
    AND SC.SHIPMENT_GID                               = AICTE.SHIPMENT_GID (+)
    AND SC.SHIPMENT_GID                               = SR.SHIPMENT_GID
    AND SC.DOMAIN_NAME                                = {DOMAIN} 
  ORDER BY 
      SC.SHIPMENT_GID DESC
),
SHIP_COST_SPLIT AS (
  SELECT 
      SC.SHIPMENT_GID
    , SUM(SC.COST)                                    COST
    , SUM(CASE WHEN  SC.INSERT_DATE <= SC.INVOICE_APPROVED_DATE OR (RD(SC.TRANSPORT_MODE_GID) NOT IN ('OCEAN-FCL','OCEAN-LCL','OCEAN','VESSEL-CO','OCEAN-FCL-ROAD','OCEAN-LCL-ROAD') AND SC.INVOICE_APPROVED_DATE IS NOT NULL) THEN SC.COST END )                                                                                  OTM_SHIPMENT_APPROVED_VALUE
    , SUM(CASE WHEN  SC.INSERT_DATE <= SC.INVOICE_REJECTED_DATE OR (RD(SC.TRANSPORT_MODE_GID) NOT IN ('OCEAN-FCL','OCEAN-LCL','OCEAN','VESSEL-CO','OCEAN-FCL-ROAD','OCEAN-LCL-ROAD') AND SC.INVOICE_REJECTED_DATE IS NOT NULL) THEN SC.COST END )                                                                                  OTM_SHIPMENT_REJECTED_VALUE
    , SUM(CASE WHEN (SC.INSERT_DATE >= SC.INVOICE_APPROVED_DATE OR SC.INVOICE_APPROVED_DATE IS NULL) OR (RD(SC.TRANSPORT_MODE_GID) NOT IN ('OCEAN-FCL','OCEAN-LCL','OCEAN','VESSEL-CO','OCEAN-FCL-ROAD','OCEAN-LCL-ROAD') AND SC.INVOICE_APPROVED_DATE IS NULL) THEN SC.COST END)                                                  OTM_SHIPMENT_ACCRUAL_VALUE
    , SUM(SC.APPROVED_INVOICE_NET_AMOUNT)             APPROVED_INVOICE_NET_AMOUNT
  FROM 
    SHIP_COST_CTE  SC
  GROUP BY 
    SC.SHIPMENT_GID
  ORDER BY 
    SC.SHIPMENT_GID DESC
),
-- Filters all data based on input parameters and predefined filters
FILTER_CTE AS
  (    
    SELECT DISTINCT
        ISCTE.SHIPMENT_GID
      , ISCTE.ORDER_RELEASE_GID
      , ISCTE.INVOICE_GID
      , (SELECT MAX(IES.EVENT_RECEIVED_DATE) FROM GLOGOWNER.IE_SHIPMENTSTATUS IES WHERE RD(IES.STATUS_CODE_GID) = 'COST_OK' AND IES.SHIPMENT_GID =ISCTE.SHIPMENT_GID)                                                                         FINAL_COST_OK_DATE
      , (SELECT MAX(IES.EVENT_RECEIVED_DATE) FROM GLOGOWNER.IE_SHIPMENTSTATUS IES WHERE RD(IES.STATUS_CODE_GID) = 'DEPARTED_ORIGIN_PORT_COST_OK' AND IES.SHIPMENT_GID =ISCTE.SHIPMENT_GID)                                                    ORIGIN_COST_OK_DATE       
    FROM 
        INV_SHIP_CTE                                  ISCTE
      , GLOGOWNER.INVOICE                             INV
    WHERE   
      INV.INVOICE_GID                                  = ISCTE.INVOICE_GID
      AND INV.DOMAIN_NAME                              = {DOMAIN}
      AND INV.ATTRIBUTE2                               IN ( 'REJECTED_OPERATIONS', 'REJECTED_CARRIER', 'ARCHIVED' )
      AND TRUNC(INV.ATTRIBUTE_DATE1)                   BETWEEN TRUNC(TO_DATE(TO_CHAR({REJECTED INVOICE FROM DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS'))  
                                                       AND TRUNC(TO_DATE(TO_CHAR({REJECTED INVOICE TO DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS'))
            AND (TRUNC(TO_DATE(TO_CHAR({REJECTED INVOICE TO DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS')) 
                - TRUNC(TO_DATE(TO_CHAR({REJECTED INVOICE FROM DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS'))) <= 365
  ), 
COST_CATEGORY_CTE AS
(
  SELECT 
    SHIPMENT_GID
    , SUM(CASE WHEN CODE =  'BASE'     THEN COST END) BASE_COST
    , SUM(CASE WHEN CODE =  'FUEL'     THEN COST END) FUEL_SURCHARGE_COST
    , SUM(CASE WHEN CODE =  'DELAY'    THEN COST END) DELAYS_COST
    , SUM(CASE WHEN CODE =  'CANCEL'   THEN COST END) CANCELLATION_CHARGE
    , SUM(CASE WHEN CODE =  'OTHER'    THEN COST END) MISCELLANEOUS
    , SUM(CASE WHEN CODE != 'BASE'     THEN COST END) ACCESSORIAL
  FROM 
    (
      SELECT
          SHIPMENT_GID
        , CASE WHEN COST_TYPE = 'B'    THEN 'BASE'
               WHEN RD(ACCESSORIAL_CODE_GID)  LIKE '%FUEL%'         OR ACCESSORIAL_CODE_GID LIKE '%FSC%'            OR ACCESSORIAL_CODE_GID LIKE '%BAF%' THEN 'FUEL'
               WHEN RD(ACCESSORIAL_CODE_GID)  LIKE '%CANCELLATION%' OR ACCESSORIAL_CODE_GID = 'CANC_CHARGES'                                             THEN 'CANCEL'
               WHEN RD(ACCESSORIAL_CODE_GID) IN ('.LEG2_O_DEM_FEE_PER_DAY','.LEG2_IMP_DET_FEES_PER_DAY','.LEG2_IMP_DEM_FEES_PER_DAY','.WAITING_TIME_CHARGE_PER_HR','.DETENTION_DEMURRAGE','.LEG2_O_DET_FEE_PER_DAY') THEN 'DELAY'
               ELSE 'OTHER' END                       CODE
        , COST                                     
      FROM 
        SHIP_COST_CTE
    )
  GROUP BY 
    SHIPMENT_GID
),
    -- Creates a location table to be used for source, destination, involved party, bill to and service provider location details
LOCATION_CTE AS 
  (
    SELECT
        L.LOCATION_GID
      , L.LOCATION_XID
      , L.LOCATION_NAME
      , L.COUNTRY_CODE3_GID                           COUNTRY_CODE
      , L.CITY
      , (SELECT LISTAGG(LA.ADDRESS_LINE, '::') WITHIN GROUP( ORDER BY LA.LINE_SEQUENCE) FROM GLOGOWNER.LOCATION_ADDRESS LA WHERE  LA.LOCATION_GID = L.LOCATION_GID)|| '::'|| L.CITY || '::' || L.POSTAL_CODE|| '::'|| L.COUNTRY_CODE3_GID     LOCATION_ADDRESS
    FROM 
      GLOGOWNER.LOCATION                              L
    WHERE 
      DOMAIN_NAME                                     = {DOMAIN}
  ),
INVOICE_REFNUM_CTE AS (
  SELECT 
      FCTE.INVOICE_GID
    , MAX(CASE WHEN IRC.INVOICE_REFNUM_QUAL_GID = {DOMAIN} ||'.CELATON_TOTAL_COST_WITH_VAT'  THEN SUBSTR(IRC.INVOICE_REFNUM_VALUE,1,LENGTH(IRC.INVOICE_REFNUM_VALUE)-4)  END)                                                                 CELATON_TOTAL_COST_WITH_VAT  
    , MAX(CASE WHEN IRC.INVOICE_REFNUM_QUAL_GID = {DOMAIN} ||'.CELATON_NET_COST'             THEN SUBSTR(IRC.INVOICE_REFNUM_VALUE,1,LENGTH(IRC.INVOICE_REFNUM_VALUE)-4)  END)                                                                 CELATON_NET_COST
  FROM 
      GLOGOWNER.INVOICE_REFNUM                        IRC
    , FILTER_CTE                                      FCTE
  WHERE
    IRC.DOMAIN_NAME                                   = {DOMAIN}
    AND( IRC.INVOICE_REFNUM_QUAL_GID                  IN ({DOMAIN} ||'.CELATON_TOTAL_COST_WITH_VAT',{DOMAIN} ||'.CELATON_NET_COST') OR  IRC.INVOICE_REFNUM_QUAL_GID LIKE {DOMAIN} ||'.CELATON_TAX_AMOUNT%' OR IRC.INVOICE_REFNUM_QUAL_GID LIKE {DOMAIN} ||'.OTM_TAX_AMOUNT%' )
    AND FCTE.INVOICE_GID =                            IRC.INVOICE_GID 
  GROUP BY
    FCTE.INVOICE_GID
),

TAX_VALUES_CTE AS (
  SELECT * FROM (
    SELECT
        COALESCE(PARENT_INVOICE_GID,I.INVOICE_GID)    PARENT_INVOICE_GID
      , TT.INVOICE_REFNUM_VALUE                       TAX_TYPE
      , NF(TV.INVOICE_REFNUM_VALUE)                   TAX_VALUE
      , NF(TP.INVOICE_REFNUM_VALUE)                   TAX_PERCENTAGE
    FROM
        GLOGOWNER.INVOICE                             I
      , GLOGOWNER.INVOICE_REFNUM                      TT
      , GLOGOWNER.INVOICE_REFNUM                      TV
      , GLOGOWNER.INVOICE_REFNUM                      TP
    WHERE
      I.DOMAIN_NAME                                   ={DOMAIN}
    --Tax Type joins
      AND I.INVOICE_GID                               = TT.INVOICE_GID
      AND REGEXP_LIKE(TT.INVOICE_REFNUM_QUAL_GID ,    '(^'||{DOMAIN}||'.OTM|^'||{DOMAIN}||'.CELATON)+.*TAX_TYPE') 
    --Tax Value Joins
      AND  TT.INVOICE_GID                             = TV.INVOICE_GID 
      AND TV.INVOICE_REFNUM_QUAL_GID                  LIKE  '%TAX_AMOUNT%'
      AND SUBSTR(TT.INVOICE_REFNUM_QUAL_GID,-1)       = SUBSTR(TV.INVOICE_REFNUM_QUAL_GID,-1)
    --Tax Percentage Joins
      AND  TT.INVOICE_GID                             = TP.INVOICE_GID 
      AND REGEXP_LIKE(TP.INVOICE_REFNUM_QUAL_GID ,    '(^'||{DOMAIN}||'.OTM|^'||{DOMAIN}||'.CELATON)+.*PERCENTAGE') 
      AND SUBSTR(TT.INVOICE_REFNUM_QUAL_GID,-1)       = SUBSTR(TP.INVOICE_REFNUM_QUAL_GID,-1)
  ) T 
  PIVOT(
      MAX(TAX_VALUE)                                  AS AMOUNT 
    , MAX(TAX_PERCENTAGE)                             AS PERCENTAGE
    FOR TAX_TYPE IN ( 
        'IIBB CABA'                                   IIBB_CABA
      , 'IIBB BA'                                     IIBB_BA
      , 'CGST'                                        CGST
      , 'IGST'                                        IGST
      , 'SGST'                                        SGST
      , 'PIS'                                         PIS
      , 'ISS'                                         ISS
      , 'COFINS'                                      COFINS
      , 'VAT'                                         VATS
      , 'RETENTION'                                   RETENTION
      , 'WITHHOLDING'                                 WITHHOLDING
      , 'IOF'                                         IOF 
      )
    )
  ORDER BY 
    PARENT_INVOICE_GID
),
 -- joins all the relevant tables bring in subquieres where summarisation is required 
MAIN_CTE AS 
  (
    SELECT
  -- SHIPMENT TABLE DATA
      S.SHIPMENT_XID                                  OTM_SHIPMENT_NUMBER
    , S.CURRENCY_GID                                  OTM_SHIPMENT_CURRENCY_GID
    , ROUND(S.TOTAL_ACTUAL_COST, 2)                   SHIPMENT_TOTAL_ACTUAL_COST
    , RD(S.TRANSPORT_MODE_GID)                        TRANSPORT_MODE
    , RD(S.SERVPROV_GID)                              CARRIER_OTM_ID
    , RD(S.FIRST_EQUIPMENT_GROUP_GID)                 EQUIPMENT_TYPE   
    , S.CHARGEABLE_WEIGHT                             ACTUAL_CHARGEABLE_WEIGHT
    -- SHIPMENT ATTRIBUTES *UPDATE*          
    , S.ATTRIBUTE1                                    OTM_SHIPMENT_STATUS   
    , CASE WHEN S.ATTRIBUTE_DATE5 IS NOT NULL THEN 'COST OK' ELSE '' END                                                                          COST_OK    
    , NVL(TD(CAST(FROM_TZ(TO_TIMESTAMP(TO_CHAR(S.ATTRIBUTE_DATE10,'DD-MON-RR HH.MI.SS AM'),'DD-MON-RR HH.MI.SS AM'),'UTC') AT TIME ZONE 'Europe/Prague' AS TIMESTAMP)),TD(UTC.GET_LOCAL_DATE(S.START_TIME, S.SOURCE_LOCATION_GID)))           SHIPMENT_COLLECTION_DATE
    , NVL(TD(CAST(FROM_TZ(TO_TIMESTAMP(TO_CHAR(S.ATTRIBUTE_DATE6,'DD-MON-RR HH.MI.SS AM'),'DD-MON-RR HH.MI.SS AM'),'UTC') AT TIME ZONE 'Europe/Prague' AS TIMESTAMP)),TD(UTC.GET_LOCAL_DATE(S.END_TIME, S.DEST_LOCATION_GID)))                SHIPMENT_DELIVERY_DATE   
    --? Changes between Order and Shipment Reports
    -- ORDER RELEASE TABLE DATA   
    , ORL.ORDER_RELEASE_XID                           ORDER_RELEASE_ID
    , RD(ORL.ORDER_RELEASE_TYPE_GID)                  ORDER_TYPE                                                                    
    , NF(ROUND(ORL.TOTAL_WEIGHT, 2))||' '|| ORL.TOTAL_WEIGHT_UOM_CODE                                                                             GROSS_WEIGHT
    -- INVOICE TABLE DATA
    , INV.INVOICE_NUMBER                              CARRIER_INVOICE_NUMBER
    , INV.NET_AMOUNT_DUE_GID                          OTM_INVOICE_CURRENCY
    , INV.INVOICE_DATE                                CARRIER_INVOICE_DATE
    , INV.INVOICE_XID || DECODE(INV.CONSOLIDATION_TYPE,'CHILD',','|| RD(INV.PARENT_INVOICE_GID))                                                  OTM_INVOICE_ID
    -- INVOICE ATTRIBUTES *UPDATE* 
    , INV.ATTRIBUTE2                                  OTM_INVOICE_STATUS
    , INV.ATTRIBUTE14                                 INVOICE_CURRENCY
    , DECODE(S.ATTRIBUTE9, 'AUDIT-ONLY', NULL, DECODE(SRCTE.FBA_PROCESS_MODE, 'MANUAL', CAST(INV.ATTRIBUTE13 AS VARCHAR(100)), CAST(IRCTE.CELATON_TOTAL_COST_WITH_VAT AS VARCHAR(100))))                                                      OTM_INVOICE_AMOUNT_GROSS
    , CASE WHEN SRCTE.FBA_PROCESS_MODE = 'MANUAL' THEN CAST(INV.ATTRIBUTE11 AS VARCHAR(100))                 ELSE  CAST(CELATON_NET_COST AS VARCHAR(100)) END                                                                                 OTM_INVOICE_AMOUNT_NET
    , CASE WHEN SRCTE.FBA_PROCESS_MODE = 'MANUAL' THEN TD(INV.ATTRIBUTE_DATE4) ELSE ( SELECT TD(TO_DATE((IR.REMARK_TEXT), 'YYYYMMDD')) FROM GLOGOWNER.INVOICE_REMARK IR WHERE IR.REMARK_QUAL_IDENTIFIER = IR.DOMAIN_NAME||'.CELATON_INVOICE_RECEIPT_DATE' AND IR.INVOICE_GID = INV.INVOICE_GID ) END                                  CARRIER_INVOICE_RECEIPT_DATE
    , CASE WHEN SRCTE.FBA_PROCESS_MODE = 'MANUAL' THEN INV.ATTRIBUTE11                                       ELSE ( SELECT SUBSTR(REMARK_TEXT,1,LENGTH(REMARK_TEXT)-4) FROM GLOGOWNER.INVOICE_REMARK IR WHERE IR.REMARK_QUAL_IDENTIFIER = IR.DOMAIN_NAME||'.CELATON_TOTAL_COST_WITH_VAT'  AND IR.INVOICE_GID = INV.INVOICE_GID  ) END CARRIER_INVOICE_VALUE_MATCHED
  -- LOCATION DATA
  -- SHIPMENT SOURCE
    , SL.LOCATION_NAME                                COLLECTION_POINT_NAME
    , SL.CITY                                         COLLECTION_POINT_CITY
    , SL.COUNTRY_CODE                                 COLLECTION_POINT_COUNTRY
    , SL.LOCATION_XID                                 COLLECTION_POINT_ID
  -- SHIPMENT DESTINATION
    , DL.LOCATION_NAME                                DELIVERY_POINT_NAME
    , DL.CITY                                         DELIVERY_POINT_CITY
    , DL.COUNTRY_CODE                                 DELIVERY_POINT_COUNTRY
    , DL.LOCATION_XID                                 DELIVERY_POINT_ID
  -- SHIPMENT SERVICE PROVIDER
    , SPL.LOCATION_NAME                               CARRIER_NAME
    , SPL.LOCATION_ADDRESS                            CARRIER_ADDRESS
    , SPL.COUNTRY_CODE                                CARRIER_COUNTRY
  -- SHIPMENT INVOLVELD PARTY
    , IPL.LOCATION_NAME                               BILL_TO_LEGAL_NAME
    , IPL.LOCATION_ADDRESS                            BILL_TO_ADDRESS
    , (SELECT MAX(LOC_REM.REMARK_TEXT) FROM GLOGOWNER.LOCATION_REMARK  LOC_REM WHERE LOC_REM.LOCATION_GID = IPL.LOCATION_GID AND LOC_REM.REMARK_QUAL_GID = LOC_REM.DOMAIN_NAME ||'.BILL_TO_VAT_NUMBER')                                       BILL_TO_VAT_NUMBER
    , (SELECT DISTINCT LISTAGG('Cost Centre-'|| LR.LOCATION_REFNUM_VALUE,', ') WITHIN GROUP( ORDER BY LOCATION_REFNUM_VALUE) FROM GLOGOWNER.LOCATION_REFNUM  LR WHERE LR.LOCATION_GID =  PID.INVOLVED_PARTY_CONTACT_GID  AND LR.LOCATION_REFNUM_QUAL_GID = LR.DOMAIN_NAME ||'.COST_CENTER' )                                          SALES_ORG
-- SUB QUERIES
   -- INVOICE SUB QUERIES  
    , DECODE(S.ATTRIBUTE9, 'AUDIT-ONLY', NULL,(SELECT MAX(RD(VAT_CODE_GID)) FROM GLOGOWNER.VAT_ANALYSIS  VA WHERE VA.INVOICE_GID = INV.INVOICE_GID))                                                                                          TREATMENT_CODE
    , (SELECT SUM(TAX_AMOUNT)          FROM GLOGOWNER.VAT_ANALYSIS VA    WHERE VA.INVOICE_GID = INV.INVOICE_GID)                                                                                                                              INVOICE_VAT_AMOUNT
   -- INVOICE STATUS SUB QUERIES 
    , (SELECT I_S.UPDATE_DATE          FROM GLOGOWNER.INVOICE_STATUS I_S WHERE RD(I_S.STATUS_TYPE_GID) = 'APPROVAL' AND I_S.INVOICE_GID = INV.INVOICE_GID)                                                                                    INVOICE_STATUS_DATE 
    -- LOCATION_REMARKS REMARK SUB QUERIES        
    , (SELECT MAX(LR.REMARK_TEXT)      FROM GLOGOWNER.LOCATION_REMARK LR WHERE RD(LR.REMARK_QUAL_GID) = 'VAT_NUMBER' AND LR.LOCATION_GID = SPL.LOCATION_GID)                                                                                  CARRIER_VAT_NUMBER
    -- RATE SUB QUERIES             
    , (SELECT TD(RG.EFFECTIVE_DATE)    FROM GLOGOWNER.RATE_GEO RG WHERE RG.RATE_GEO_GID = S.RATE_GEO_GID)                                         RATES_EFFECTIVE_FROM
    , (SELECT TD(RG.EXPIRATION_DATE)   FROM GLOGOWNER.RATE_GEO RG WHERE RG.RATE_GEO_GID = S.RATE_GEO_GID)                                         RATES_EFFECTIVE_TO 
-- Underbilling calculations
    , ROUND(SCCTE.APPROVED_INVOICE_NET_AMOUNT - S.TOTAL_ACTUAL_COST,2)                                                                            UNDER_BILLED_AMOUNT
    , CASE WHEN ROUND(SCCTE.APPROVED_INVOICE_NET_AMOUNT - S.TOTAL_ACTUAL_COST ,2) <0 THEN 'YES' ELSE 'NO' END                                     UNDER_BILLED
  --? Changes between Order and Shipment Reports     
  -- ALLOCATION SUB QUERIES     
    , (SELECT ROUND(SUM( A.TOTAL_ALLOC_COST / TO_CURRENCY('EUR' , A.TOTAL_COST_CURRENCY_GID, A.EXCHANGE_RATE_DATE, A.EXCHANGE_RATE_GID)*TO_CURRENCY( 'EUR', SRCTE.OTM_CURRENCY, A.EXCHANGE_RATE_DATE, A.EXCHANGE_RATE_GID)),2) FROM GLOGOWNER.ALLOCATION_BASE AB, GLOGOWNER.ALLOCATION  A WHERE AB.ALLOC_TYPE_QUAL_GID = 'PLANNING' AND AB.SHIPMENT_GID = S.SHIPMENT_GID AND A.SHIPMENT_GID = AB.SHIPMENT_GID AND A.ALLOC_SEQ_NO = AB.ALLOC_SEQ_NO AND A.ORDER_RELEASE_GID = ORL.ORDER_RELEASE_GID) APPORTIONED_OTM_SHIPMENT
  -- SHIPMENT REFNUM CTE SUB QUERIES
    , SRCTE.OTM_CURRENCY                              MASTER_RATE_CURRENCY
    , SRCTE.FBA_PROCESS_MODE
    , SRCTE.PMER_EXCHANGE_RATE
    , SRCTE.LANE_ID
    , SRCTE.FBA_RESPONSIBILITY_STATUS
    , SRCTE.SHIPMENT_TOTAL_TAX    
  -- SHIPMENT COST CTE SUB QUERIES                      
    , CC.DELAYS_COST
    , CC.CANCELLATION_CHARGE
    , CC.MISCELLANEOUS
    , CC.FUEL_SURCHARGE_COST
    , ROUND(CC.BASE_COST,2)                           SHIPMENT_BASE_COST 
    , CC.ACCESSORIAL                                  SHIPMENT_ACCESSORIAL_COST
  -- SHIPMENT COST CTE SUB QUERIES
    , SCCTE.OTM_SHIPMENT_APPROVED_VALUE
    , SCCTE.OTM_SHIPMENT_ACCRUAL_VALUE
    , SCCTE.OTM_SHIPMENT_REJECTED_VALUE
  -- Filter CTE subquery fields 
    , FCTE.FINAL_COST_OK_DATE
    , FCTE.ORIGIN_COST_OK_DATE
  -- Tax Mapping
    , TCTE.IIBB_CABA_AMOUNT
    , TCTE.IIBB_BA_AMOUNT
    , TCTE.CGST_AMOUNT
    , TCTE.IGST_AMOUNT
    , TCTE.SGST_AMOUNT
    , TCTE.PIS_AMOUNT
    , TCTE.ISS_AMOUNT
    , TCTE.COFINS_AMOUNT
    , TCTE.IOF_AMOUNT
    , TCTE.RETENTION_AMOUNT
    , TCTE.WITHHOLDING_AMOUNT
    , TCTE.VATS_AMOUNT
    , TCTE.IIBB_CABA_PERCENTAGE
    , TCTE.IIBB_BA_PERCENTAGE
    , TCTE.CGST_PERCENTAGE
    , TCTE.IGST_PERCENTAGE
    , TCTE.SGST_PERCENTAGE
    , TCTE.PIS_PERCENTAGE
    , TCTE.ISS_PERCENTAGE
    , TCTE.COFINS_PERCENTAGE
    , TCTE.IOF_PERCENTAGE
    , TCTE.RETENTION_PERCENTAGE
    , TCTE.WITHHOLDING_PERCENTAGE
    , TCTE.VATS_PERCENTAGE
    , IRCTE.CELATON_TOTAL_COST_WITH_VAT
    , IRCTE.CELATON_NET_COST
    FROM
      GLOGOWNER.INVOICE                               INV
    , GLOGOWNER.SHIPMENT                              S
    , GLOGOWNER.SHIPMENT_INVOLVED_PARTY               SIP
    , GLOGOWNER.ORDER_RELEASE                         ORL
    , GLOGOWNER.SHIPMENT_INVOLVED_PARTY               PID
    , GLOGOWNER.RATE_OFFERING                         RO
    --CTE TABLES 
    , FILTER_CTE                                      FCTE
    , COST_CATEGORY_CTE                               CC
    , LOCATION_CTE                                    SL
    , LOCATION_CTE                                    DL
    , LOCATION_CTE                                    SPL
    , LOCATION_CTE                                    IPL
    , TAX_VALUES_CTE                                  TCTE
    , INVOICE_REFNUM_CTE                              IRCTE
    , SHIP_COST_SPLIT                                 SCCTE
    , SHIP_REFNUM_CTE                                 SRCTE

  WHERE
      S.DOMAIN_NAME                                     = {DOMAIN}
      AND SIP.INVOLVED_PARTY_QUAL_GID                   = S.DOMAIN_NAME ||'.BILL_TO'
      AND S.SHIPMENT_GID                                = SIP.SHIPMENT_GID
      AND S.SHIPMENT_GID                                = PID.SHIPMENT_GID(+)
      AND PID.INVOLVED_PARTY_QUAL_GID                   = S.DOMAIN_NAME ||'.PLANT_ID'
      AND S.RATE_OFFERING_GID                           = RO.RATE_OFFERING_GID (+) 
  -- CTE JOINS
      AND S.SHIPMENT_GID                                = SRCTE.SHIPMENT_GID
      AND S.SOURCE_LOCATION_GID                         = SL.LOCATION_GID
      AND S.DEST_LOCATION_GID                           = DL.LOCATION_GID
      AND S.SERVPROV_GID                                = SPL.LOCATION_GID
      AND SIP.INVOLVED_PARTY_CONTACT_GID                = IPL.LOCATION_GID(+)
      AND S.SHIPMENT_GID                                = CC.SHIPMENT_GID (+) 
      AND INV.INVOICE_GID                               = FCTE.INVOICE_GID
      AND ORL.ORDER_RELEASE_GID                         = FCTE.ORDER_RELEASE_GID
      AND S.SHIPMENT_GID                                = FCTE.SHIPMENT_GID
      AND COALESCE(INV.PARENT_INVOICE_GID,INV.INVOICE_GID)= TCTE.PARENT_INVOICE_GID (+)
      AND INV.INVOICE_GID                               = IRCTE.INVOICE_GID (+)
      AND S.SHIPMENT_GID                                = SCCTE.SHIPMENT_GID
  -- WHERE CLAUSE WITH PARAMETERS 
      AND ((SIP.INVOLVED_PARTY_CONTACT_GID              IN ({BILL TO LEGAL NAME})) OR {BILL TO LEGAL NAME} IS NULL)
      AND ({TREATMENT CODE}                             IN ( SELECT REPLACE(VAT_CODE_GID,VA.DOMAIN_NAME ||'.') FROM GLOGOWNER.VAT_ANALYSIS VA WHERE VA.INVOICE_GID = INV.INVOICE_GID) OR {TREATMENT CODE} IS NULL )
      AND ({BUSINESS UNIT}                              IN PID.INVOLVED_PARTY_CONTACT_GID  OR {BUSINESS UNIT} IS NULL )
      AND ({CARRIER NAME}                               IN SPL.LOCATION_NAME OR {CARRIER NAME} IS NULL)
      AND ({FBA RESPONSIBILITY STATUS}                  IN SRCTE.FBA_RESPONSIBILITY_STATUS OR {FBA RESPONSIBILITY STATUS} IS NULL)
)
       -- final select statment to organise the fields for the report viewer
SELECT        
    OTM_SHIPMENT_NUMBER                               "OTM Shipment ID"
  , ORDER_RELEASE_ID                                  "Order Release"
  , ORDER_TYPE                                        "Order Type"
  , SALES_ORG                                         "sales Org"
  , FBA_RESPONSIBILITY_STATUS                         "FBA OTM Responsibility Status"
  , BILL_TO_LEGAL_NAME                                "Bill to Legal Name"
  , BILL_TO_ADDRESS                                   "Bill to Address"
  , BILL_TO_VAT_NUMBER                                "Bill to VAT Number"
  , OTM_INVOICE_ID                                    "Carrier Invoice ID"
  , CARRIER_INVOICE_NUMBER                            "Carrier Invoice Number"
  , TD(CARRIER_INVOICE_DATE)                          "Carrier Invoice Date"
  , CARRIER_INVOICE_RECEIPT_DATE                      "Carrier Invoice Receipt Date"
  , CARRIER_NAME                                      "Carrier Name"
  , CARRIER_ADDRESS                                   "Carrier Address"
  , CARRIER_VAT_NUMBER                                "Carrier VAT Number"
  , CARRIER_OTM_ID                                    "Carrier OTM ID"
  , CARRIER_COUNTRY                                   "Carrier Country"   
  , SHIPMENT_COLLECTION_DATE                          "Shipment Collection Date"
  , SHIPMENT_DELIVERY_DATE                            "Shipment Delivery Date"
  , COLLECTION_POINT_NAME                             "Collection Point Name"
  , COLLECTION_POINT_CITY                             "Collection Point City"
  , COLLECTION_POINT_COUNTRY                          "Collection Point Country Code"
  , COLLECTION_POINT_ID                               "Collection Point ID"
  , DELIVERY_POINT_NAME                               "Delivery Point Name"
  , DELIVERY_POINT_CITY                               "Delivery Point City"
  , DELIVERY_POINT_COUNTRY                            "Delivery Point Country code"
  , DELIVERY_POINT_ID                                 "Delivery Point ID"
  , TRANSPORT_MODE                                    "Mode"
  , EQUIPMENT_TYPE                                    "Equipment Type"
  , LANE_ID                                           "Lane ID"
  , RATES_EFFECTIVE_FROM                              "Date Rates Effective From / Rate Version ID"
  , RATES_EFFECTIVE_TO                                "Date Rates Effective To / Rate Version ID"
  , GROSS_WEIGHT                                      "Gross Weight KG"
  , NF(ACTUAL_CHARGEABLE_WEIGHT)                      "Base Actual Weight KG"
  , NF(SHIPMENT_BASE_COST)                            "OTM Shipment Freight Cost (BASE)"
  , NF(FUEL_SURCHARGE_COST)                           "OTM Shipment Fuel Surcharge Cost"
  , NF(ROUND(DELAYS_COST, 2))                         "OTM Shipment Delays total (Inc demurrage/waiting time)"
  , NF(ROUND(CANCELLATION_CHARGE, 2))                 "OTM Shipment Cancellation Cost"
  , NF(ROUND(MISCELLANEOUS, 2))                       "OTM Shipment Miscellaneous Cost"
  , NF(ROUND(SHIPMENT_ACCESSORIAL_COST,2))            "OTM Shipment Freight Accessorial Cost"
  , NF(SHIPMENT_TOTAL_ACTUAL_COST)                    "OTM Shipment Total Freight Cost"
  , NF(SHIPMENT_TOTAL_TAX)                            "OTM Order / Shipment Total Tax Value"
  , NF(OTM_SHIPMENT_APPROVED_VALUE)                   "OTM Shipment Approved Value"
  , NF(OTM_SHIPMENT_ACCRUAL_VALUE)                    "OTM Shipment Accrual Value"
--, NF(ROUND(UNDER_BILLED_AMOUNT,2))                  "OTM Shipment Underbilled Amount"
--, NF(OTM_SHIPMENT_REJECTED_VALUE)                   "OTM Shipment Rejected Value"
  , NF(APPORTIONED_OTM_SHIPMENT)                      "OTM Shipment Apportioned Value"
  , MASTER_RATE_CURRENCY                              "OTM Shipment Currency"
  , NF(OTM_INVOICE_AMOUNT_NET)                        "Carrier Invoice Amount(Net)"
  , NF(INVOICE_VAT_AMOUNT)                            "Carrier Invoice Total Tax Value"
  , NF(OTM_INVOICE_AMOUNT_GROSS)                      "Carrier Invoice Gross Value"
  , VATS_PERCENTAGE                                   "Carrier Invoice VAT Percentage"
  , VATS_AMOUNT                                       "Carrier Invoice VAT Amount Value"
  , CGST_PERCENTAGE                                   "Carrier Invoice CGST Percentage"
  , CGST_AMOUNT                                       "Carrier Invoice CGST Value"
  , IGST_PERCENTAGE                                   "Carrier Invoice IGST Percentage"
  , IGST_AMOUNT                                       "Carrier Invoice IGST Value"
  , SGST_PERCENTAGE                                   "Carrier Invoice SGST Percentage"
  , SGST_AMOUNT                                       "Carrier Invoice SGST Value"
  , IIBB_CABA_PERCENTAGE                              "Carrier Invoice IIBB CABA Percentage"
  , IIBB_CABA_AMOUNT                                  "Carrier Invoice IIBB CABA Value"
  , IIBB_BA_PERCENTAGE                                "Carrier Invoice IIBB BA Percentage"
  , IIBB_BA_AMOUNT                                    "Carrier Invoice IIBB BA Value" 
  , IOF_PERCENTAGE                                    "Carrier Invoice IOF Percentage"
  , IOF_AMOUNT                                        "Carrier Invoice IOF Value"
  , PIS_PERCENTAGE                                    "Carrier Invoice PIS Percentage"
  , PIS_AMOUNT                                        "Carrier Invoice PIS Value"
  , ISS_PERCENTAGE                                    "Carrier Invoice ISS Percentage"
  , ISS_AMOUNT                                        "Carrier Invoice ISS Value"
  , COFINS_PERCENTAGE                                 "Carrier Invoice COFINS Percentage"
  , COFINS_AMOUNT                                     "Carrier Invoice COFINS Value"
  , RETENTION_PERCENTAGE                              "Carrier Invoice Retention Percentage"
  , RETENTION_AMOUNT                                  "Carrier Invoice Retention Value"
  , WITHHOLDING_PERCENTAGE                            "Carrier Invoice Withholding Tax Percentage"        
  , WITHHOLDING_AMOUNT                                "Carrier Invoice Withholding Tax Value"
  , NF(CARRIER_INVOICE_VALUE_MATCHED)                 "Carrier Invoice Net Value Matched against Order / Shipment Net Value"
  , OTM_INVOICE_CURRENCY                              "Carrier Invoice Shipment Currency"
  , COST_OK                                           "Cost OK Milestone"
  , TD(FINAL_COST_OK_DATE)                            "Cost Ok Date"
  , OTM_INVOICE_STATUS                                "OTM Invoice status"
  , TD(INVOICE_STATUS_DATE)                           "Invoice “Approved” status Date"
  , OTM_SHIPMENT_STATUS                               "Shipment Status"
  , FBA_PROCESS_MODE                                  "FBA Process Mode"
  , PMER_EXCHANGE_RATE                                "PMER Exchange rate (master carrier currency to EURO)"
  , TD(ORIGIN_COST_OK_DATE)                           "Origin Cost OK Date"
  , TD(FINAL_COST_OK_DATE)                            "Final Cost OK Date"
FROM 
  MAIN_CTE
ORDER BY  
    OTM_SHIPMENT_NUMBER
  , ACTUAL_CHARGEABLE_WEIGHT
  , ORDER_RELEASE_ID
  , OTM_INVOICE_ID     