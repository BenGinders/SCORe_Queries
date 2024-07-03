--! 04.BAT Invoice Backup (Order Level)
-- > Notes
    --   > Accessorial codes can vary between accounts
    --   > Attribute columns need to be validated for each account
    --   > 10 refnum, remark and status columns are used, which can vary between accounts
   
    --   > VARIANCES TO ORDER / SHIPMENT
    --   > Filter_CTE uses INVOICE_GID, SHIPMENT_GID AND ORDER_RELEASE_GID instead of SHIPMENT_GID

  -- ! PARAMETERS
    --  ? INLINE PARAMETERS 
      --       :INVOICE_ID
      --       :SHIPMENT_ID  
    --  ? INPUT PARAMETERS
      --       {FBA RESPONSIBILITY STATUS}
      --       {DOMAIN}
      --       {BILL TO LEGAL NAME}
      --       {BUSINESS UNIT}
      --       {APPROVED FROM DATE}
      --       {APPROVED TO DATE}
      --       {TREATMENT CODE}
      --       {CARRIER NAME}
  -- ! ATTRIBUTES 
    --  ? SHIPMENT 
      --      S.ATTRIBUTE_DATE6   -  SHIPMENT_DELIVERY_DATE
      --      S.ATTRIBUTE_DATE10  -  SHIPMENT_COLLECTION_DATE
      --      S.ATTRIBUTE_DATE5   -  OTM_COST_OK_DATE
      --      S.ATTRIBUTE9        -  FBA_RESPONSIBILITY_STATUS
    --  ? INVOICE
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
  IS BEGIN RETURN REPLACE(GID, {DOMAIN}||'.');
END;
FUNCTION TD(DT TIMESTAMP) RETURN VARCHAR2
  IS BEGIN RETURN TO_CHAR(DT, 'DD/MM/YYYY hh24:mi:ss');
END;
FUNCTION NF(NUM VARCHAR2) RETURN VARCHAR2
  IS BEGIN 
   IF (VALIDATE_CONVERSION(NUM AS NUMBER) = 0)  THEN RETURN NUM;
   ELSE RETURN TO_CHAR(ROUND(NUM,2), 'FM999G999G999G990D00');
END IF;
END;
-- Creates a table with both Automatic and Manual invoices to be used in later queries for joins
INV_SHIP_CTE AS
  ( 
    SELECT
        OM.SHIPMENT_GID
        , INVS.INVOICE_GID
        , OM.ORDER_RELEASE_GID
    FROM
          GLOGOWNER.INVOICE_SHIPMENT                    INVS
        , GLOGOWNER.ORDER_MOVEMENT                      OM
        , GLOGOWNER.INVOICE                             INV
        , GLOGOWNER.INVOICE_REMARK                      IR
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
SHIP_REFNUM_CTE AS (
  SELECT
    SR.SHIPMENT_GID
  , MAX(CASE SR.SHIPMENT_REFNUM_QUAL_GID                WHEN SR.DOMAIN_NAME ||'.GBP_EXCH_RATE' THEN TO_CHAR(SHIPMENT_REFNUM_VALUE,'FM9D99999')  END)                             PMER_EXCHANGE_RATE 
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

-- Filters all data based on input parameters and predefined filters
FILTER_CTE AS 
  (
    SELECT DISTINCT
      ISCTE.SHIPMENT_GID
    , ISCTE.ORDER_RELEASE_GID
    , ISCTE.INVOICE_GID
    , (SELECT MAX(IES.EVENTDATE) FROM GLOGOWNER.IE_SHIPMENTSTATUS IES, GLOGOWNER.SS_STATUS_HISTORY SSH WHERE IES.STATUS_CODE_GID = {DOMAIN}||'.DELIVERY CONFIRMED(POD RECEIVED)' AND IES.I_TRANSACTION_NO = SSH.I_TRANSACTION_NO  AND SSH.SHIPMENT_GID =ISCTE.SHIPMENT_GID)                                                DELIVERY_CONFIRMED_DATE             
    FROM
       INV_SHIP_CTE                                   ISCTE
      , GLOGOWNER.INVOICE_STATUS                      INVST     
      , GLOGOWNER.SHIPMENT                            S 
    WHERE 
      INVST.INVOICE_GID                               = ISCTE.INVOICE_GID
      AND ISCTE.SHIPMENT_GID                          = S.SHIPMENT_GID
      AND S.ATTRIBUTE4                                = 'ROC'
      AND INVST.DOMAIN_NAME                           = {DOMAIN}
      AND INVST.STATUS_TYPE_GID                       = {DOMAIN}||'.APPROVAL'
      AND INVST.STATUS_VALUE_GID                      IN ({DOMAIN}||'.APPROVAL_APPROVED_AUTO',{DOMAIN}||'.APPROVAL_APPROVED_MANUAL')
      AND INVST.UPDATE_DATE                           BETWEEN TRUNC(TO_DATE(TO_CHAR({APPROVED FROM DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS'))
                                                      AND TRUNC(TO_DATE(TO_CHAR({APPROVED TO DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS'))
      AND (TRUNC(TO_DATE(TO_CHAR({APPROVED TO DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS'))
          - TRUNC(TO_DATE(TO_CHAR({APPROVED FROM DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS'))) <= 365
),  
SHIP_COST_CTE AS (
  SELECT
      SC.SHIPMENT_GID
    , (SC.COST / TO_CURRENCY('EUR' , sc.COST_GID, SC.EXCHANGE_RATE_DATE, SC.EXCHANGE_RATE_GID))*TO_CURRENCY( 'EUR', S.CURRENCY_GID , SC.EXCHANGE_RATE_DATE, SC.EXCHANGE_RATE_GID) COST
    , SC.COST_TYPE
    , SC.ACCESSORIAL_CODE_GID
    , SC.ADJUSTMENT_REASON_GID
  FROM 
      GLOGOWNER.SHIPMENT_COST                         SC 
    , GLOGOWNER.SHIPMENT                              S
  WHERE 
    SC.SHIPMENT_GID                                   = S.SHIPMENT_GID  
    AND SC.DOMAIN_NAME                                = {DOMAIN} 
    AND                                               EXISTS (SELECT 1 FROM FILTER_CTE FCTE WHERE FCTE.SHIPMENT_GID = SC.SHIPMENT_GID) 
),
COST_CATEGORY_CTE AS
(
  SELECT 
    SC.SHIPMENT_GID
    , SUM(CASE SC.COST_TYPE WHEN 'B' THEN COST END)                                                                                                       BASE_COST
    , SUM(CASE WHEN SC.ACCESSORIAL_CODE_GID LIKE '%FUEL%' OR SC.ACCESSORIAL_CODE_GID LIKE '%FSC%' OR SC.ACCESSORIAL_CODE_GID LIKE '%BAF%' THEN COST END)  FUEL_SURCHARGE_COST
    , SUM(CASE WHEN SC.ADJUSTMENT_REASON_GID IN ('B1','B2','B3','B5','B7','B9','B10','A4','A5') THEN COST END)                                            DELAYS_COST
    , SUM(CASE WHEN SC.ADJUSTMENT_REASON_GID IN ('A1','A2','A3','A4','A5') THEN COST END)                                                                 CANCELLATION_CHARGE
    , SUM(CASE WHEN SC.COST_TYPE != 'B' 
            AND (SC.ACCESSORIAL_CODE_GID NOT LIKE '%FUEL%' AND SC.ACCESSORIAL_CODE_GID NOT LIKE '%FSC%' AND SC.ACCESSORIAL_CODE_GID NOT LIKE '%BAF%') 
            AND SC.ADJUSTMENT_REASON_GID NOT IN ('A1','A2','A3','A4','A5', 'B1','B2','B3','B5','B7','B9','B10') THEN COST END)                            MISCELLANEOUS
    , SUM(CASE WHEN SC.COST_TYPE != 'B' THEN COST END)                                                                                                    ACCESSORIAL
 FROM 
    SHIP_COST_CTE                                     SC
 GROUP BY 
    SC.SHIPMENT_GID


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
INVOICE_REMARK_CTE AS (
  SELECT 
      FCTE.INVOICE_GID
    , MAX(CASE WHEN IRC.REMARK_QUAL_IDENTIFIER = {DOMAIN} ||'.CELATON_TOTAL_COST_WITH_VAT'  THEN SUBSTR(IRC.REMARK_TEXT,1,LENGTH(IRC.REMARK_TEXT)-4)  END)                                                                                    CELATON_TOTAL_COST_WITH_VAT
    , MAX(CASE WHEN IRC.REMARK_QUAL_IDENTIFIER = {DOMAIN} ||'.CELATON_NET_COST'             THEN SUBSTR(IRC.REMARK_TEXT,1,LENGTH(IRC.REMARK_TEXT)-4)  END)                                                                                    CELATON_NET_COST
  FROM 
    GLOGOWNER.INVOICE_REMARK                          IRC
  , FILTER_CTE                                        FCTE
  WHERE
    IRC.DOMAIN_NAME                                   = {DOMAIN}
    AND( IRC.REMARK_QUAL_IDENTIFIER                   IN ({DOMAIN} ||'.CELATON_TOTAL_COST_WITH_VAT',{DOMAIN} ||'.CELATON_NET_COST'))
    AND FCTE.INVOICE_GID =                            IRC.INVOICE_GID 
  GROUP BY
    FCTE.INVOICE_GID
),
ALLOCATION_CTE AS (
    SELECT 
        SHIPMENT_GID
      , ORDER_RELEASE_GID
      , CASE WHEN TOTAL_WEIGHT  >0 THEN COST_APPORTIONED_WEIGHT ELSE ORDER_COUNT_APPORTIONMENT  END                                               COST_APPORTION_PERCENTAGE
    FROM (
        SELECT 
            OM.SHIPMENT_GID 
          , ORL.ORDER_RELEASE_GID 
          , ORL.TOTAL_WEIGHT
          , SUM(ORL.TOTAL_WEIGHT) OVER (PARTITION BY OM.ORDER_RELEASE_GID)  / NULLIF(SUM(ORL.TOTAL_WEIGHT) OVER (PARTITION BY OM.SHIPMENT_GID),0)  COST_APPORTIONED_WEIGHT
          , 1/COUNT(ORL.ORDER_RELEASE_GID) OVER (PARTITION BY OM.SHIPMENT_GID)                                                                     ORDER_COUNT_APPORTIONMENT
        FROM 
            GLOGOWNER.ORDER_RELEASE                       ORL 
          , GLOGOWNER.ORDER_MOVEMENT                      OM 
        WHERE 
            OM.DOMAIN_NAME                                = {DOMAIN} 
            AND OM.ORDER_RELEASE_GID                      = ORL.ORDER_RELEASE_GID
            AND                                           EXISTS (SELECT 1 FROM FILTER_CTE FCTE WHERE FCTE.SHIPMENT_GID = OM.SHIPMENT_GID) 
    )
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
    , (SELECT RD(STATUS_VALUE_GID) FROM GLOGOWNER.SHIPMENT_STATUS WHERE STATUS_TYPE_GID = {DOMAIN}||'.SHIPMENT STATUS' AND SHIPMENT_GID = S.SHIPMENT_GID)                              OTM_SHIPMENT_STATUS           
    , CASE WHEN FCTE.DELIVERY_CONFIRMED_DATE  IS NOT NULL THEN 'DELIVERY CONFIRMED(POD RECEIVED)' ELSE '' END                                                                          DELIVERY_CONFIRMED  
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
    , INV.CURRENCY_GID                                INVOICE_CURRENCY
    , DECODE(S.ATTRIBUTE9, 'AUDIT-ONLY', NULL, DECODE(SRCTE.FBA_PROCESS_MODE, 'MANUAL', CAST(INV.NET_AMT_DUE_WITH_TAX AS VARCHAR(100)), CAST(IRCTE.CELATON_TOTAL_COST_WITH_VAT AS VARCHAR(100))))                                                OTM_INVOICE_AMOUNT_GROSS
    , CASE WHEN SRCTE.FBA_PROCESS_MODE = 'MANUAL' THEN CAST(INV.NET_AMOUNT_DUE AS VARCHAR(100))                 ELSE  CAST(CELATON_NET_COST AS VARCHAR(100)) END                                                                                 OTM_INVOICE_AMOUNT_NET
    , CASE WHEN SRCTE.FBA_PROCESS_MODE = 'MANUAL' THEN TD(INV.ATTRIBUTE_DATE4) ELSE ( SELECT TD(TO_DATE((IR.REMARK_TEXT), 'YYYYMMDD')) FROM GLOGOWNER.INVOICE_REMARK IR WHERE IR.REMARK_QUAL_IDENTIFIER = IR.DOMAIN_NAME||'.CELATON_INVOICE_RECEIPT_DATE' AND IR.INVOICE_GID = INV.INVOICE_GID ) END                                  CARRIER_INVOICE_RECEIPT_DATE
    , CASE WHEN SRCTE.FBA_PROCESS_MODE = 'MANUAL' THEN NF(INV.NET_AMOUNT_DUE)                                       ELSE ( SELECT SUBSTR(REMARK_TEXT,1,LENGTH(REMARK_TEXT)-4) FROM GLOGOWNER.INVOICE_REMARK IR WHERE IR.REMARK_QUAL_IDENTIFIER = IR.DOMAIN_NAME||'.CELATON_TOTAL_COST_WITH_VAT'  AND IR.INVOICE_GID = INV.INVOICE_GID  ) END CARRIER_INVOICE_VALUE_MATCHED
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
  -- SUB QUERIES  
  -- INVOICE SUB QUERIES
    , DECODE(S.ATTRIBUTE9, 'AUDIT-ONLY', NULL,(SELECT MAX(RD(VAT_CODE_GID)) FROM GLOGOWNER.VAT_ANALYSIS  VA WHERE VA.INVOICE_GID = INV.INVOICE_GID))                                                                                          TREATMENT_CODE
    , (SELECT SUM(TAX_AMOUNT)          FROM GLOGOWNER.VAT_ANALYSIS VA    WHERE VA.INVOICE_GID = INV.INVOICE_GID)                                                                                                                              INVOICE_VAT_AMOUNT
   -- INVOICE STATUS SUB QUERIES
    , (SELECT I_S.UPDATE_DATE          FROM GLOGOWNER.INVOICE_STATUS I_S WHERE I_S.STATUS_TYPE_GID = {DOMAIN}||'.APPROVAL' AND I_S.INVOICE_GID = INV.INVOICE_GID)                                                                             INVOICE_STATUS_DATE
  -- LOCATION_REMARKS REMARK SUB QUERIES        
    , (SELECT MAX(LR.REMARK_TEXT)      FROM GLOGOWNER.LOCATION_REMARK LR WHERE LR.REMARK_QUAL_GID = {DOMAIN}||'.VAT_NUMBER' AND LR.LOCATION_GID = SPL.LOCATION_GID)                                                                           CARRIER_VAT_NUMBER
  -- RATE SUB QUERIES       
    , (SELECT TD(RG.EFFECTIVE_DATE)    FROM GLOGOWNER.RATE_GEO RG WHERE RG.RATE_GEO_GID = S.RATE_GEO_GID)                                         RATES_EFFECTIVE_FROM
    , (SELECT TD(RG.EXPIRATION_DATE)   FROM GLOGOWNER.RATE_GEO RG WHERE RG.RATE_GEO_GID = S.RATE_GEO_GID)                                         RATES_EFFECTIVE_TO 
  --? Changes between Order and Shipment Reports     
  -- ALLOCATION SUB QUERIES      
   , S.TOTAL_ACTUAL_COST *  (SELECT SUM(AC.COST_APPORTION_PERCENTAGE) FROM ALLOCATION_CTE AC WHERE AC.SHIPMENT_GID = S.SHIPMENT_GID AND AC.ORDER_RELEASE_GID = ORL.ORDER_RELEASE_GID)                                                         APPORTIONED_OTM_SHIPMENT
  -- SHIPMENT REFNUM CTE SUB QUERIES
    , SRCTE.OTM_CURRENCY                              MASTER_RATE_CURRENCY
    , SRCTE.FBA_PROCESS_MODE
    , NVL(SRCTE.PMER_EXCHANGE_RATE , TO_CURRENCY('GBP',S.CURRENCY_GID, S.EXCHANGE_RATE_DATE, S.EXCHANGE_RATE_GID ))	                              PMER_EXCHANGE_RATE
    --, SRCTE.LANE_ID
    , SL.COUNTRY_CODE || '_' || DL.COUNTRY_CODE || '_' || (SELECT DECODE(T.MODE_TYPE,'TL','ROAD', T.MODE_TYPE) FROM GLOGOWNER.TRANSPORT_MODE T WHERE T.TRANSPORT_MODE_GID =S.TRANSPORT_MODE_GID)                                              LANE_ID
    --, SRCTE.FBA_RESPONSIBILITY_STATUS
    , SRCTE.SHIPMENT_TOTAL_TAX  
  -- SHIPMENT COST CTE SUB QUERIES 
    , CC.DELAYS_COST
    , CC.CANCELLATION_CHARGE
    , CC.MISCELLANEOUS
    , CC.FUEL_SURCHARGE_COST
    , ROUND(CC.BASE_COST,2)                             SHIPMENT_BASE_COST
    , CC.ACCESSORIAL                                    SHIPMENT_ACCESSORIAL_COST

  -- Filter CTE subquery fields 
    , FCTE.DELIVERY_CONFIRMED_DATE 
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
      , INVOICE_REMARK_CTE                              IRCTE
      , SHIP_REFNUM_CTE                                 SRCTE

    WHERE
      S.DOMAIN_NAME                                     = {DOMAIN}
      AND SIP.INVOLVED_PARTY_QUAL_GID                   = 'BILL_TO' 
      AND S.SHIPMENT_GID                                = SIP.SHIPMENT_GID
      AND S.SHIPMENT_GID                                = PID.SHIPMENT_GID(+)
      AND PID.INVOLVED_PARTY_QUAL_GID (+)               = S.DOMAIN_NAME ||'.SEND_TO'
      AND S.RATE_OFFERING_GID                           = RO.RATE_OFFERING_GID (+) 
        -- CTE JOINS
      AND S.SHIPMENT_GID                                = SRCTE.SHIPMENT_GID  
      AND S.SOURCE_LOCATION_GID                         = SL.LOCATION_GID
      AND S.DEST_LOCATION_GID                           = DL.LOCATION_GID
      AND S.SERVPROV_GID                                = SPL.LOCATION_GID
      AND SIP.INVOLVED_PARTY_CONTACT_GID                = IPL.LOCATION_GID(+)  
      AND S.SHIPMENT_GID                                = CC.SHIPMENT_GID
      AND INV.INVOICE_GID                               = FCTE.INVOICE_GID
      AND ORL.ORDER_RELEASE_GID                         = FCTE.ORDER_RELEASE_GID
      AND S.SHIPMENT_GID                                = FCTE.SHIPMENT_GID
      AND INV.INVOICE_GID                               = IRCTE.INVOICE_GID (+)
-- WHERE CLAUSE WITH PARAMETERS
      AND ((SIP.INVOLVED_PARTY_CONTACT_GID              IN ({BILL TO LEGAL NAME})) OR {BILL TO LEGAL NAME} IS NULL)
      AND ({TREATMENT CODE}                             IN ( SELECT {DOMAIN}||'.'||VAT_CODE_GID,VA.DOMAIN_NAME ||'.') FROM GLOGOWNER.VAT_ANALYSIS VA WHERE VA.INVOICE_GID = INV.INVOICE_GID) OR {TREATMENT CODE} IS NULL )
      AND ({BUSINESS UNIT}                              IN PID.INVOLVED_PARTY_CONTACT_GID  OR {BUSINESS UNIT} IS NULL )
      AND ({CARRIER NAME}                               IN SPL.LOCATION_NAME OR {CARRIER NAME} IS NULL)
      AND ({FBA RESPONSIBILITY STATUS}                  IN SRCTE.FBA_RESPONSIBILITY_STATUS OR {FBA RESPONSIBILITY STATUS} IS NULL)
    )
-- final select statment to organise the fields for the report viewer
SELECT        
    OTM_SHIPMENT_NUMBER                               "OTM Shipment ID"
  , ORDER_RELEASE_ID                                  "Order Release"
  , ORDER_TYPE                                        "Order Type"
  --, FBA_RESPONSIBILITY_STATUS                         "FBA OTM Responsibility Status"
  , BILL_TO_LEGAL_NAME                                "Bill to Legal Name"
  , BILL_TO_ADDRESS                                   "Bill to Address"
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
  , NF(SHIPMENT_ACCESSORIAL_COST)                     "OTM Shipment Freight Accessorial Cost"
  , NF(FUEL_SURCHARGE_COST)                           "OTM Shipment Fuel Surcharge Cost"
  , NF(SHIPMENT_TOTAL_ACTUAL_COST)                    "OTM Shipment Total Freight Cost"
  , NF(DELAYS_COST)                                   "OTM Shipment Delays total (Inc demurrage/waiting time)"
  , NF(CANCELLATION_CHARGE)                           "OTM Shipment Cancellation Cost"
  , NF(MISCELLANEOUS)                                 "OTM Shipment Miscellaneous Cost"
  , NF(SHIPMENT_TOTAL_ACTUAL_COST)                    "OTM Order / Shipment Total Cost"
  , NF(APPORTIONED_OTM_SHIPMENT)                      "OTM Shipment Apportioned %"
  , MASTER_RATE_CURRENCY                              "OTM Shipment Currency"
  , DELIVERY_CONFIRMED                                 "Delivery Confirmed Milestone"
  , TD(DELIVERY_CONFIRMED_DATE)                       "Delivery Confirmed Date"
  , FBA_PROCESS_MODE                                  "FBA Process Mode"
  , NF(CARRIER_INVOICE_VALUE_MATCHED)                 "Carrier Invoice Value Matched against Order / Shipment"
  , OTM_INVOICE_CURRENCY                              "Carrier Invoice Shipment Currency"
  , NF(OTM_INVOICE_AMOUNT_NET)                        "OTM Invoice Amount(Net)"
  , INVOICE_VAT_AMOUNT                                "OTM Invoice VAT Amount"
  , NF(OTM_INVOICE_AMOUNT_GROSS)                      "OTM Invoice Amount With VAT(GROSS)"
  , TREATMENT_CODE                                    "Carrier Invoice VAT Treatment Code"
  , OTM_INVOICE_STATUS                                "OTM Invoice status"
  , TD(INVOICE_STATUS_DATE)                           "Invoice “Approved” status Date"
  , OTM_SHIPMENT_STATUS                               "Shipment Status"
  , PMER_EXCHANGE_RATE                                "PMER Exchange rate (master carrier currency to GBP)"

FROM 
  MAIN_CTE
ORDER BY  
    OTM_SHIPMENT_NUMBER
  , ACTUAL_CHARGEABLE_WEIGHT
  , ORDER_RELEASE_ID
  , OTM_INVOICE_ID       