--! 04.IFF Rejected Invoice (Order Level) 
-- > Notes
    --   > Only 'COST4', 'COST5' and 'OTHERS' are used from the COST_CATEGORY_CTE and categorirs need to be reviewed
   
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
      --       {CUSTOMER_ID}
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
-- Creates a table with both Automatic and Manual invoices to be used in later queries for joins
INV_SHIP_CTE AS
    ( 
        SELECT
        DISTINCT
            OM.SHIPMENT_GID
            , INVS.INVOICE_GID
            , OM.ORDER_RELEASE_GID
            , INV.ATTRIBUTE2                                             INVOICE_STATUS
        FROM
              GLOGOWNER.INVOICE_SHIPMENT                                 INVS
            , GLOGOWNER.ORDER_MOVEMENT                                   OM
            , GLOGOWNER.INVOICE                                          INV
            , INVOICE_REMARK                                             IR
        WHERE
            OM.DOMAIN_NAME                                               = {DOMAIN}
            AND INV.ATTRIBUTE2 (+)                                       NOT IN ('ARCHIVED', 'ARCHIVED_RPA_ERROR')
            AND INV.INVOICE_GID (+)                                      = INVS.INVOICE_GID
            AND INVS.SHIPMENT_GID (+)                                    = OM.SHIPMENT_GID  
            AND IR.REMARK_QUAL_IDENTIFIER (+)                            = {DOMAIN}||'.CELATON_SHIPMENT_ID'
            AND IR.REMARK_SEQ_NO (+)                                     = 15
            AND OM.SHIPMENT_GID                                          = IR.REMARK_TEXT (+) 
            AND IR.REMARK_TEXT                                           IS NULL
    UNION      
        SELECT
        DISTINCT
            OM.SHIPMENT_GID
            , IR.INVOICE_GID
            , OM.ORDER_RELEASE_GID
            , INV.ATTRIBUTE2                                             INVOICE_STATUS
        FROM
              GLOGOWNER.INVOICE_REMARK                                   IR
            , GLOGOWNER.ORDER_MOVEMENT                                   OM
            , GLOGOWNER.INVOICE                                          INV
        WHERE
            OM.SHIPMENT_GID                                              =  IR.REMARK_TEXT
            AND IR.REMARK_QUAL_IDENTIFIER                                = {DOMAIN}|| '.CELATON_SHIPMENT_ID'
            AND IR.REMARK_SEQ_NO                                         = 15
            AND INV.INVOICE_GID                                          = IR.INVOICE_GID
            AND INV.ATTRIBUTE2                                           NOT IN ('ARCHIVED', 'ARCHIVED_RPA_ERROR')
            AND OM.DOMAIN_NAME                                           = {DOMAIN}
    ), 
APPR_INVOICE_CTE AS (
    SELECT
        ISCTE.SHIPMENT_GID,
        MAX(INVS.ATTRIBUTE_DATE8)                                   INVOICE_APPROVED_DATE,
        MAX(INVS.ATTRIBUTE_DATE1)                                   INVOICE_REJECTED_DATE
    FROM 
        INVOICE                                                     INVS
      , INV_SHIP_CTE                                                ISCTE
    WHERE 
        INVS.INVOICE_GID                                            = ISCTE.INVOICE_GID
    GROUP BY 
      ISCTE.SHIPMENT_GID
    , INVS.DOMAIN_NAME  
),
SHIP_REFNUM_CTE AS (
        SELECT
          SR.SHIPMENT_GID
        , MAX(CASE SR.SHIPMENT_REFNUM_QUAL_GID                WHEN SR.DOMAIN_NAME ||'.EUR_EXCHANGE_RATE' THEN TO_CHAR(SHIPMENT_REFNUM_VALUE,'FM9D99999')  END)  PMER_EXCHANGE_RATE 
        , MAX(CASE SR.SHIPMENT_REFNUM_QUAL_GID                WHEN SR.DOMAIN_NAME ||'.LANE_ID'           THEN SHIPMENT_REFNUM_VALUE END)                        LANE_ID         
        , LISTAGG(DISTINCT CASE SR.SHIPMENT_REFNUM_QUAL_GID   WHEN SR.DOMAIN_NAME ||'.LLP_RESPONSIBILITY'THEN  SHIPMENT_REFNUM_VALUE END)                       FBA_RESPONSIBILITY_STATUS
        , MAX(CASE SR.SHIPMENT_REFNUM_QUAL_GID                WHEN SR.DOMAIN_NAME ||'.FBA_PROCESS_MODE'  THEN SHIPMENT_REFNUM_VALUE END)                        FBA_PROCESS_MODE
        , SUM(CASE                                            WHEN SR.SHIPMENT_REFNUM_QUAL_GID LIKE '%TAX_AMOUNT%'THEN SHIPMENT_REFNUM_VALUE END)               SHIPMENT_TOTAL_TAX 
        , MAX(CASE SR.SHIPMENT_REFNUM_QUAL_GID                WHEN SR.DOMAIN_NAME ||'.OTM_CURRENCY'      THEN SHIPMENT_REFNUM_VALUE END)                        OTM_CURRENCY
        FROM 
            GLOGOWNER.SHIPMENT_REFNUM SR 
        WHERE 
            DOMAIN_NAME = {DOMAIN} 
        GROUP BY 
            SR.SHIPMENT_GID
),

SHIP_COST_CTE AS (
        SELECT
            SC.SHIPMENT_GID
          , (SC.COST / TO_CURRENCY('EUR' , sc.COST_GID, SC.EXCHANGE_RATE_DATE, SC.EXCHANGE_RATE_GID))*TO_CURRENCY( 'EUR', SR.OTM_CURRENCY , SC.EXCHANGE_RATE_DATE, SC.EXCHANGE_RATE_GID) AS SHIPMENT_COST
          , SC.INSERT_DATE                                         INSERT_DATE
          , SC.DOMAIN_NAME
          , SC.COST_TYPE
          , SC.ACCESSORIAL_CODE_GID
          , AICTE.INVOICE_APPROVED_DATE
          , AICTE.INVOICE_REJECTED_DATE
          , S.TRANSPORT_MODE_GID
        FROM 
            GLOGOWNER.SHIPMENT_COST                                SC 
          , GLOGOWNER.SHIPMENT                                     S
          , APPR_INVOICE_CTE                                       AICTE
          , SHIP_REFNUM_CTE                                        SR
        WHERE 
          SC.SHIPMENT_GID                                          = S.SHIPMENT_GID  
          AND SC.SHIPMENT_GID                                      = AICTE.SHIPMENT_GID (+)
          AND SC.SHIPMENT_GID                                      = SR.SHIPMENT_GID
          AND SC.DOMAIN_NAME                                       = {DOMAIN} 
        ORDER BY 
            SC.SHIPMENT_GID DESC
),
SHIP_COST_SPLIT AS (
      SELECT 
        SC.SHIPMENT_GID
      , SUM(SC.SHIPMENT_COST)                                    SHIPMENT_COST
      , SUM(CASE 
          WHEN 
            SC.INSERT_DATE <= SC.INVOICE_APPROVED_DATE 
            OR (
                  SC.TRANSPORT_MODE_GID NOT IN ({DOMAIN}||'.OCEAN-FCL', {DOMAIN}||'.OCEAN-LCL', {DOMAIN}||'.OCEAN', {DOMAIN}||'.VESSEL-CO', {DOMAIN}||'.OCEAN-FCL-ROAD', {DOMAIN}||'.OCEAN-LCL-ROAD') 
                  AND SC.INVOICE_APPROVED_DATE IS NOT NULL
              )
          THEN SC.SHIPMENT_COST END )                           OTM_SHIPMENT_APPROVED_VALUE
        , SUM(CASE 
          WHEN 
            SC.INSERT_DATE <= SC.INVOICE_REJECTED_DATE 
            OR (
                  SC.TRANSPORT_MODE_GID NOT IN ({DOMAIN}||'.OCEAN-FCL', {DOMAIN}||'.OCEAN-LCL', {DOMAIN}||'.OCEAN', {DOMAIN}||'.VESSEL-CO', {DOMAIN}||'.OCEAN-FCL-ROAD', {DOMAIN}||'.OCEAN-LCL-ROAD') 
                  AND SC.INVOICE_REJECTED_DATE IS NOT NULL
              )
          THEN SC.SHIPMENT_COST END )                           OTM_SHIPMENT_REJECTED_VALUE
      , SUM(CASE 
          WHEN 
             (SC.INSERT_DATE >= SC.INVOICE_APPROVED_DATE OR SC.INVOICE_APPROVED_DATE IS NULL)
            OR (
                  SC.TRANSPORT_MODE_GID NOT IN ({DOMAIN}||'.OCEAN-FCL', {DOMAIN}||'.OCEAN-LCL', {DOMAIN}||'.OCEAN', {DOMAIN}||'.VESSEL-CO', {DOMAIN}||'.OCEAN-FCL-ROAD', {DOMAIN}||'.OCEAN-LCL-ROAD') 
                  AND SC.INVOICE_APPROVED_DATE IS NULL
              )
          THEN SC.SHIPMENT_COST END)                            OTM_SHIPMENT_ACCRUAL_VALUE

      FROM SHIP_COST_CTE  SC
      GROUP BY SC.SHIPMENT_GID
      ORDER BY SC.SHIPMENT_GID DESC
),

-- Filters all data based on input parameters and predefined filters
FILTER_CTE AS
  (    
    SELECT DISTINCT
      ISCTE.SHIPMENT_GID
    , ISCTE.ORDER_RELEASE_GID
    , ISCTE.INVOICE_GID
    , INV.ATTRIBUTE11                                                                                                                                                                               TOTAL_SHIPMENT_INVOICE_NET_AMOUNT
    -- , SUM(CASE WHEN INV.ATTRIBUTE2 IN ( 'REJECTED_OPERATIONS', 'REJECTED_CARRIER', 'ARCHIVED' ) THEN SHIPMENT_COST END)                                           APPORTIONED_OCEAN_FREIGHT
    , (SELECT MAX(IES.EVENT_RECEIVED_DATE) FROM GLOGOWNER.IE_SHIPMENTSTATUS IES WHERE IES.STATUS_CODE_GID = {DOMAIN} ||'.COST_OK' AND IES.SHIPMENT_GID =ISCTE.SHIPMENT_GID)                         FINAL_COST_OK_DATE
    , (SELECT MAX(IES.EVENT_RECEIVED_DATE) FROM GLOGOWNER.IE_SHIPMENTSTATUS IES WHERE IES.STATUS_CODE_GID = {DOMAIN} ||'.DEPARTED_ORIGIN_PORT_COST_OK' AND IES.SHIPMENT_GID =ISCTE.SHIPMENT_GID)    ORIGIN_COST_OK_DATE
    --, SUM(OFCTE.SHIPMENT_COST)                                     SHIPMENT_COST          
    FROM 
      INV_SHIP_CTE                                                 ISCTE
    , GLOGOWNER.INVOICE                                            INV
    WHERE   
      INV.INVOICE_GID                                              = ISCTE.INVOICE_GID
      AND INV.DOMAIN_NAME                                          = {DOMAIN}
      AND INV.ATTRIBUTE2                                           IN ( 'REJECTED_OPERATIONS', 'REJECTED_CARRIER', 'ARCHIVED' )
      AND TRUNC(INV.ATTRIBUTE_DATE1)                                                    BETWEEN TRUNC(TO_DATE(TO_CHAR({REJECTED INVOICE FROM DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS'))  
                                                                                        AND TRUNC(TO_DATE(TO_CHAR({REJECTED INVOICE TO DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS'))
            AND (TRUNC(TO_DATE(TO_CHAR({REJECTED INVOICE TO DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS')) 
                - TRUNC(TO_DATE(TO_CHAR({REJECTED INVOICE FROM DATE},'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS'))) <= 365
     GROUP BY       
      ISCTE.SHIPMENT_GID                                                                
    , ISCTE.ORDER_RELEASE_GID
    , ISCTE.INVOICE_GID
    , INV.ATTRIBUTE11
), 
COST_CATEGORY_CTE AS
(
  SELECT 
    SHIPMENT_GID
    , SUM(CASE WHEN DESCRIPTION = 'BASE_COST' THEN  SHIPMENT_COST END)            BASE_COST
    , SUM(CASE WHEN DESCRIPTION = 'FUEL_SURCHARGE_COST' THEN  SHIPMENT_COST END)  FUEL_SURCHARGE_COST
    , SUM(CASE WHEN DESCRIPTION = 'DELAYS_COST' THEN  SHIPMENT_COST END)          DELAYS_COST
    , SUM(CASE WHEN DESCRIPTION = 'CANCELLATION_COST' THEN  SHIPMENT_COST END)    CANCELLATION_CHARGE
    , SUM(CASE WHEN DESCRIPTION = 'OTHER_COST'THEN SHIPMENT_COST END)             MISCELLANEOUS
  FROM 
    (
      SELECT
          SHIPMENT_GID
        , CASE 
            WHEN COST_TYPE = 'B' THEN 'BASE_COST'
            WHEN ACCESSORIAL_CODE_GID  LIKE {DOMAIN}||'.%FUEL%' OR ACCESSORIAL_CODE_GID LIKE {DOMAIN}||'.%FSC%' OR ACCESSORIAL_CODE_GID LIKE {DOMAIN}||'.%BAF%' THEN 'FUEL_SURCHARGE_COST'
            WHEN ACCESSORIAL_CODE_GID  LIKE {DOMAIN}||'.CANCELLATION%' OR ACCESSORIAL_CODE_GID = {DOMAIN}||'.CANC_CHARGES' THEN 'CANCELLATION_COST'
            WHEN REPLACE(ACCESSORIAL_CODE_GID,{DOMAIN}) IN ('.LEG2_O_DEM_FEE_PER_DAY','.LEG2_IMP_DET_FEES_PER_DAY','.LEG2_IMP_DEM_FEES_PER_DAY','.WAITING_TIME_CHARGE_PER_HR','.DETENTION_DEMURRAGE','.LEG2_O_DET_FEE_PER_DAY') THEN 'DELAYS_COST'
            ELSE 'OTHER_COST'
          END DESCRIPTION
        , SHIPMENT_COST
      FROM 
      SHIP_COST_CTE
    )
  GROUP BY 
    SHIPMENT_GID
),
COST_EVENTS_CTE AS (
    SELECT 
        IES.SHIPMENT_GID
      , MAX( CASE STATUS_CODE_GID WHEN {DOMAIN} ||'.COST_OK' THEN CAST(FROM_TZ(CAST(EVENTDATE AS TIMESTAMP ),'UTC') AT TIME ZONE TIME_ZONE_GID AS TIMESTAMP(0))END)                       COK_DATE
      , MAX(CASE STATUS_CODE_GID WHEN {DOMAIN} ||'.DEPARTED_ORIGIN_PORT_COST_OK' THEN CAST(FROM_TZ(CAST(EVENTDATE AS TIMESTAMP ),'UTC') AT TIME ZONE TIME_ZONE_GID AS TIMESTAMP(0)) END)  ORIGIN_COK_DATE
    FROM
        GLOGOWNER.IE_SHIPMENTSTATUS                                  IES
    WHERE
        IES.DOMAIN_NAME                                              = {DOMAIN} 
        AND IES.STATUS_CODE_GID                                      IN ({DOMAIN} ||'.COST_OK', {DOMAIN} ||'.DEPARTED_ORIGIN_PORT_COST_OK')
    GROUP BY
        IES.SHIPMENT_GID
), 
    -- Creates a location table to be used for source, destination, involved party, bill to and service provider location details
LOCATION_CTE AS 
  (
    SELECT
      L.LOCATION_GID
    , L.LOCATION_XID
    , L.LOCATION_NAME
    , L.COUNTRY_CODE3_GID                                            COUNTRY_CODE
    , L.CITY
    , (SELECT LISTAGG(LA.ADDRESS_LINE, '::') WITHIN GROUP( ORDER BY LA.LINE_SEQUENCE) FROM GLOGOWNER.LOCATION_ADDRESS LA WHERE  LA.LOCATION_GID = L.LOCATION_GID)|| '::'|| L.CITY || '::' || L.POSTAL_CODE|| '::'|| L.COUNTRY_CODE3_GID LOCATION_ADDRESS
    FROM 
      GLOGOWNER.LOCATION                                             L
    WHERE 
      DOMAIN_NAME                                                    = {DOMAIN}
  ),
INVOICE_REFNUM_CTE AS (
    SELECT 
      FCTE.INVOICE_GID
      , MAX(CASE WHEN IRC.INVOICE_REFNUM_QUAL_GID = {DOMAIN} ||'.CELATON_TOTAL_COST_WITH_VAT'  THEN SUBSTR(IRC.INVOICE_REFNUM_VALUE,1,LENGTH(IRC.INVOICE_REFNUM_VALUE)-4)  END)                       CELATON_TOTAL_COST_WITH_VAT    
      , MAX(CASE WHEN IRC.INVOICE_REFNUM_QUAL_GID = {DOMAIN} ||'.CELATON_NET_COST'             THEN SUBSTR(IRC.INVOICE_REFNUM_VALUE,1,LENGTH(IRC.INVOICE_REFNUM_VALUE)-4)  END)                       CELATON_NET_COST
    FROM 
      GLOGOWNER.INVOICE_REFNUM                                       IRC
    , FILTER_CTE                                                     FCTE
    WHERE
      IRC.DOMAIN_NAME                                                = {DOMAIN}
      AND( IRC.INVOICE_REFNUM_QUAL_GID                               IN ({DOMAIN} ||'.CELATON_TOTAL_COST_WITH_VAT',{DOMAIN} ||'.CELATON_NET_COST') OR  IRC.INVOICE_REFNUM_QUAL_GID LIKE {DOMAIN} ||'.CELATON_TAX_AMOUNT%' OR IRC.INVOICE_REFNUM_QUAL_GID LIKE {DOMAIN} ||'.OTM_TAX_AMOUNT%' )
      AND FCTE.INVOICE_GID =                                         IRC.INVOICE_GID 
    GROUP BY
      FCTE.INVOICE_GID
),

TAX_VALUES_CTE AS (
    SELECT * FROM (
        SELECT
            COALESCE(PARENT_INVOICE_GID,I.INVOICE_GID)               PARENT_INVOICE_GID
          , TT.INVOICE_REFNUM_VALUE                                  TAX_TYPE
          , TO_CHAR(TV.INVOICE_REFNUM_VALUE,'FM999G999G990D00')      TAX_VALUE
          , TO_CHAR(TP.INVOICE_REFNUM_VALUE,'FM999G999G990D00')      TAX_PERCENTAGE
        FROM
            GLOGOWNER.INVOICE                                        I
          , GLOGOWNER.INVOICE_REFNUM                                 TT
          , GLOGOWNER.INVOICE_REFNUM                                 TV
          , GLOGOWNER.INVOICE_REFNUM                                 TP
        WHERE
            I.DOMAIN_NAME                                            ={DOMAIN}
        --Tax Type joins
            AND I.INVOICE_GID                                        = TT.INVOICE_GID
            AND REGEXP_LIKE(TT.INVOICE_REFNUM_QUAL_GID ,             '(^'||{DOMAIN}||'.OTM|^'||{DOMAIN}||'.CELATON)+.*TAX_TYPE') 
        --Tax Value Joins
            AND  TT.INVOICE_GID                                      = TV.INVOICE_GID 
            AND TV.INVOICE_REFNUM_QUAL_GID                           LIKE  '%TAX_AMOUNT%'
            AND SUBSTR(TT.INVOICE_REFNUM_QUAL_GID,-1)                = SUBSTR(TV.INVOICE_REFNUM_QUAL_GID,-1)
        --Tax Percentage Joins
            AND  TT.INVOICE_GID                                      = TP.INVOICE_GID 
            AND REGEXP_LIKE(TP.INVOICE_REFNUM_QUAL_GID ,             '(^'||{DOMAIN}||'.OTM|^'||{DOMAIN}||'.CELATON)+.*PERCENTAGE') 
            AND SUBSTR(TT.INVOICE_REFNUM_QUAL_GID,-1)                = SUBSTR(TP.INVOICE_REFNUM_QUAL_GID,-1)
    ) T 
    PIVOT(
        MAX(TAX_VALUE)                                               AS AMOUNT, 
        MAX(TAX_PERCENTAGE)                                          AS PERCENTAGE
    FOR TAX_TYPE IN ( 
              'IIBB CABA'                                            IIBB_CABA
            , 'IIBB BA'                                              IIBB_BA
            , 'CGST'                                                 CGST
            , 'IGST'                                                 IGST
            , 'SGST'                                                 SGST
            , 'PIS'                                                  PIS
            , 'ISS'                                                  ISS
            , 'COFINS'                                               COFINS
            , 'VAT'                                                  VATS
            , 'RETENTION'                                            RETENTION
            , 'WITHHOLDING'                                          WITHHOLDING
            , 'IOF'                                                  IOF 
            )
        )
    ORDER BY PARENT_INVOICE_GID
),
 -- joins all the relevant tables bring in subquieres where summarisation is required 
MAIN_CTE AS 
  (
    SELECT
    -- SHIPMENT TABLE DATA
      S.SHIPMENT_XID                                                 OTM_SHIPMENT_NUMBER
    , S.CURRENCY_GID                                                 OTM_SHIPMENT_CURRENCY_GID
    , ROUND(S.TOTAL_ACTUAL_COST, 2)                                  SHIPMENT_TOTAL_ACTUAL_COST
    , REPLACE(S.TRANSPORT_MODE_GID, S.DOMAIN_NAME ||'.')             TRANSPORT_MODE
    , REPLACE(S.SERVPROV_GID, S.DOMAIN_NAME ||'.')                   CARRIER_OTM_ID
    , REPLACE(S.PAYMENT_METHOD_CODE_GID, S.DOMAIN_NAME ||'.')        CUSTOMER_ID
    , REPLACE(S.FIRST_EQUIPMENT_GROUP_GID, S.DOMAIN_NAME ||'.')      EQUIPMENT_TYPE
    , TO_CHAR(FCTE.ORIGIN_COST_OK_DATE,'DD/MM/YYYY HH24:MI:SS')      ORIGIN_COST_OK_DATE
    , TO_CHAR(FCTE.FINAL_COST_OK_DATE,'DD/MM/YYYY HH24:MI:SS')       FINAL_COST_OK_DATE
    , S.CHARGEABLE_WEIGHT                                            ACTUAL_CHARGEABLE_WEIGHT
    --? Changes between Order and Shipment Reports              
    -- SHIPMENT ATTRIBUTES *UPDATE* 
      --S.ATTRIBUTE9                                                 FBA_RESPONSIBILITY_STATUS
    , S.ATTRIBUTE1                                                   OTM_SHIPMENT_STATUS   
    , TO_CHAR(S.ATTRIBUTE_DATE5,'DD/MM/YYYY HH24:MI:SS')             OTM_COST_OK_DATE
    , CASE WHEN S.ATTRIBUTE_DATE5 IS NOT NULL THEN 'COST OK' ELSE '' END                                                                            COST_OK    
    , NVL(TO_CHAR(CAST(FROM_TZ(TO_TIMESTAMP(to_CHAR(S.ATTRIBUTE_DATE10,'DD-MON-RR HH.MI.SS AM'),'DD-MON-RR HH.MI.SS AM'),'UTC') AT TIME ZONE 'Europe/Prague' AS TIMESTAMP),'DD/MM/YYYY HH24:MI:SS')  ,TO_CHAR(UTC.GET_LOCAL_DATE(S.START_TIME, S.SOURCE_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))          SHIPMENT_COLLECTION_DATE
    , NVL(TO_CHAR(CAST(FROM_TZ(TO_TIMESTAMP(to_CHAR(S.ATTRIBUTE_DATE6,'DD-MON-RR HH.MI.SS AM'),'DD-MON-RR HH.MI.SS AM'),'UTC') AT TIME ZONE 'Europe/Prague' AS TIMESTAMP),'DD/MM/YYYY HH24:MI:SS')  ,TO_CHAR(UTC.GET_LOCAL_DATE(S.END_TIME, S.DEST_LOCATION_GID),'DD/MM/YYYY HH24:MI:SS'))               SHIPMENT_DELIVERY_DATE
    --? Changes between Order and Shipment Reports
    -- ORDER RELEASE TABLE DATA   
    , ORL.ORDER_RELEASE_XID                                          ORDER_RELEASE_ID
    , REPLACE(ORL.ORDER_RELEASE_TYPE_GID, ORL.DOMAIN_NAME||'.')      ORDER_TYPE                                                                    
    , TO_CHAR(ROUND(ORL.TOTAL_WEIGHT, 2),'FM999G999G990D00')|| ' '|| ORL.TOTAL_WEIGHT_UOM_CODE                                                      GROSS_WEIGHT
    -- INVOICE TABLE DATA
    , INV.INVOICE_NUMBER                                             CARRIER_INVOICE_NUMBER
    , INV.NET_AMOUNT_DUE_GID                                         OTM_INVOICE_CURRENCY
    , ROUND(INV.NET_AMOUNT_DUE, 2)                                   OTM_INVOICE_VALUE
    , TO_CHAR(INV.INVOICE_DATE, 'DD/MM/YYYY hh24:mi:ss')             CARRIER_INVOICE_DATE
    , INV.INVOICE_XID || DECODE(INV.CONSOLIDATION_TYPE,'CHILD',','|| REPLACE(INV.PARENT_INVOICE_GID, INV.DOMAIN_NAME||'.'))                         OTM_INVOICE_ID
    -- INVOICE ATTRIBUTES *UPDATE* 
    , INV.ATTRIBUTE2                                                 OTM_INVOICE_STATUS
    , INV.ATTRIBUTE14                                                INVOICE_CURRENCY
    , CASE WHEN SRCTE.FBA_PROCESS_MODE = 'MANUAL' THEN CAST(INV.ATTRIBUTE11 AS VARCHAR(100))  ELSE  CAST(CELATON_NET_COST AS VARCHAR(100)) END    OTM_INVOICE_AMOUNT_NET
    , DECODE(S.ATTRIBUTE9, 'AUDIT-ONLY', NULL, CASE WHEN SRCTE.FBA_PROCESS_MODE = 'MANUAL' THEN CAST(INV.ATTRIBUTE13 AS VARCHAR(100)) ELSE CAST(CELATON_TOTAL_COST_WITH_VAT AS VARCHAR(100)) END)       OTM_INVOICE_AMOUNT_GROSS
    , CASE WHEN SRCTE.FBA_PROCESS_MODE = 'MANUAL' THEN  TO_CHAR(INV.ATTRIBUTE_DATE4, 'DD/MM/YYYY HH24:MI:SS') ELSE ( SELECT TO_CHAR(TO_DATE((IR.REMARK_TEXT), 'YYYYMMDD'), 'DD/MM/YYYY HH24:MI:SS') FROM GLOGOWNER.INVOICE_REMARK IR WHERE IR.REMARK_QUAL_IDENTIFIER = IR.DOMAIN_NAME||'.CELATON_INVOICE_RECEIPT_DATE' AND IR.INVOICE_GID = INV.INVOICE_GID ) END CARRIER_INVOICE_RECEIPT_DATE
    , CASE WHEN  SRCTE.FBA_PROCESS_MODE = 'MANUAL' THEN   INV.ATTRIBUTE11 ELSE ( SELECT SUBSTR(REMARK_TEXT,1,LENGTH(REMARK_TEXT)-4) FROM GLOGOWNER.INVOICE_REMARK IR WHERE IR.REMARK_QUAL_IDENTIFIER = IR.DOMAIN_NAME||'.CELATON_TOTAL_COST_WITH_VAT'  AND IR.INVOICE_GID = INV.INVOICE_GID  ) END  CARRIER_INVOICE_VALUE_MATCHED
    , ROUND( S.TOTAL_ACTUAL_COST -FCTE.TOTAL_SHIPMENT_INVOICE_NET_AMOUNT,2)                                                                         UNDER_BILLED_AMOUNT
    , CASE WHEN ROUND( FCTE.TOTAL_SHIPMENT_INVOICE_NET_AMOUNT-S.TOTAL_ACTUAL_COST ,2) >0 THEN 'YES' ELSE 'NO' END                                   UNDER_BILLED
-- LOCATION DATA
    -- SHIPMENT SOURCE
    , SL.LOCATION_NAME                                               COLLECTION_POINT_NAME
    , SL.CITY                                                        COLLECTION_POINT_CITY
    , SL.COUNTRY_CODE                                                COLLECTION_POINT_COUNTRY
    , SL.LOCATION_XID                                                COLLECTION_POINT_ID
    -- SHIPMENT DESTINATION
    , DL.LOCATION_NAME                                               DELIVERY_POINT_NAME
    , DL.CITY                                                        DELIVERY_POINT_CITY
    , DL.COUNTRY_CODE                                                DELIVERY_POINT_COUNTRY
    , DL.LOCATION_XID                                                DELIVERY_POINT_ID
    -- SHIPMENT SERVICE PROVIDER
    , SPL.LOCATION_NAME                                              CARRIER_NAME
    , SPL.LOCATION_ADDRESS                                           CARRIER_ADDRESS
    , SPL.COUNTRY_CODE                                               CARRIER_COUNTRY
    -- SHIPMENT INVOLVELD PARTY
    , IPL.LOCATION_NAME                                              BILL_TO_LEGAL_NAME
    , IPL.LOCATION_ADDRESS                                           BILL_TO_ADDRESS
    , (SELECT MAX(LOC_REM.REMARK_TEXT) FROM GLOGOWNER.LOCATION_REMARK  LOC_REM WHERE LOC_REM.LOCATION_GID = IPL.LOCATION_GID AND LOC_REM.REMARK_QUAL_GID = LOC_REM.DOMAIN_NAME ||'.BILL_TO_VAT_NUMBER')                                     BILL_TO_VAT_NUMBER
, (SELECT DISTINCT LISTAGG('Cost Centre-'|| LR.LOCATION_REFNUM_VALUE,', ') WITHIN GROUP( ORDER BY LOCATION_REFNUM_VALUE) FROM GLOGOWNER.LOCATION_REFNUM  LR WHERE LR.LOCATION_GID =  PID.INVOLVED_PARTY_CONTACT_GID  AND LR.LOCATION_REFNUM_QUAL_GID = LR.DOMAIN_NAME ||'.COST_CENTER' )       SALES_ORG
-- SUB QUERIES
    -- INVOICE SUB QUERIES  
    , CASE WHEN S.ATTRIBUTE9 = 'AUDIT-ONLY' THEN NULL ELSE (SELECT REPLACE(VAT_CODE_GID, VA.DOMAIN_NAME||'.') FROM GLOGOWNER.VAT_ANALYSIS  VA WHERE VA.INVOICE_GID = INV.INVOICE_GID AND ROWNUM=1) END    TREATMENT_CODE
    , (SELECT SUM(TAX_AMOUNT) FROM GLOGOWNER.VAT_ANALYSIS  VA WHERE VA.INVOICE_GID = INV.INVOICE_GID)                                                                                                     INVOICE_VAT_AMOUNT
    , (SELECT TO_CHAR(I_S.UPDATE_DATE, 'DD/MM/YYYY hh24:mi:ss') FROM GLOGOWNER.INVOICE_STATUS I_S WHERE I_S.STATUS_TYPE_GID = I_S.DOMAIN_NAME ||'.APPROVAL' AND I_S.INVOICE_GID = INV.INVOICE_GID)        INVOICE_STATUS_DATE 
    -- RATE SUB QUERIES             
    , (SELECT TO_CHAR(RG.EFFECTIVE_DATE, 'DD/MM/YYYY hh24:mi:ss') FROM GLOGOWNER.RATE_GEO RG WHERE RG.RATE_GEO_GID = S.RATE_GEO_GID)                                                                      RATES_EFFECTIVE_FROM
    , (SELECT TO_CHAR(RG.EXPIRATION_DATE, 'DD/MM/YYYY hh24:mi:ss') FROM GLOGOWNER.RATE_GEO RG WHERE RG.RATE_GEO_GID = S.RATE_GEO_GID)                                                                     RATES_EFFECTIVE_TO
    , SRCTE.OTM_CURRENCY                                                                                                                                                                                  MASTER_RATE_CURRENCY
    , CASE WHEN RO.CURRENCY_GID=S.CURRENCY_GID THEN 1 ELSE (1/ TO_CURRENCY('EUR',RO.CURRENCY_GID,S.EXCHANGE_RATE_DATE,S.EXCHANGE_RATE_GID))* TO_CURRENCY('EUR',SRCTE.OTM_CURRENCY,S.EXCHANGE_RATE_DATE,S.EXCHANGE_RATE_GID) END  RATE_CARD_VS_PROCURED_CURRENCY 
  -- ALLOCATION SUB QUERIES     
    , (SELECT ROUND(SUM( A.TOTAL_ALLOC_COST / TO_CURRENCY('EUR', A.TOTAL_COST_CURRENCY_GID, A.EXCHANGE_RATE_DATE, A.EXCHANGE_RATE_GID)*TO_CURRENCY( 'EUR', SRCTE.OTM_CURRENCY, A.EXCHANGE_RATE_DATE, A.EXCHANGE_RATE_GID)),2) FROM GLOGOWNER.ALLOCATION_BASE AB, GLOGOWNER.ALLOCATION  A WHERE AB.ALLOC_TYPE_QUAL_GID = 'PLANNING' AND AB.SHIPMENT_GID = S.SHIPMENT_GID AND A.SHIPMENT_GID = AB.SHIPMENT_GID AND A.ALLOC_SEQ_NO = AB.ALLOC_SEQ_NO AND A.ORDER_RELEASE_GID = ORL.ORDER_RELEASE_GID)  APPORTIONED_OTM_SHIPMENT
    -- SHIPMENT REFNUM SUB QUERIES
    ,  SRCTE.FBA_PROCESS_MODE
    ,  SRCTE.PMER_EXCHANGE_RATE
    ,  SRCTE.LANE_ID
    ,  SRCTE.FBA_RESPONSIBILITY_STATUS
    ,  SRCTE.SHIPMENT_TOTAL_TAX    
    -- SHIPMENT COST CTE SUB QUERIES                      
    , CC.DELAYS_COST
    , CC.CANCELLATION_CHARGE
    , CC.MISCELLANEOUS
    , CC.FUEL_SURCHARGE_COST
    , ROUND(CC.BASE_COST,2)                                     SHIPMENT_BASE_COST
    , (NVL(CC.DELAYS_COST,0) + NVL(CC.CANCELLATION_CHARGE,0) + NVL(CC.MISCELLANEOUS,0) + NVL(CC.FUEL_SURCHARGE_COST,0)) SHIPMENT_ACCESSORIAL_COST
    -- SHIPMENT COST SUB QUERIES
    , SCCTE.OTM_SHIPMENT_APPROVED_VALUE
    , SCCTE.OTM_SHIPMENT_ACCRUAL_VALUE
    , SCCTE.OTM_SHIPMENT_REJECTED_VALUE
    , CECTE.COK_DATE
    -- SHIPMENT STOP LOCATION
    , (SELECT L.LOCATION_NAME FROM GLOGOWNER.SHIPMENT_STOP SS, GLOGOWNER.LOCATION L WHERE SS.SHIPMENT_GID = S.SHIPMENT_GID AND SS.LOCATION_GID = L.LOCATION_GID AND STOP_TYPE = 'P' AND STOP_NUM = ( SELECT MIN(SS1.STOP_NUM) FROM GLOGOWNER.SHIPMENT_STOP SS1 WHERE SS1.SHIPMENT_GID = S.SHIPMENT_GID))     ORIGINAL_ORDER_COLLECTION_POINT_NAME
    , (SELECT L.LOCATION_NAME FROM GLOGOWNER.SHIPMENT_STOP SS, GLOGOWNER.LOCATION L WHERE SS.SHIPMENT_GID = S.SHIPMENT_GID AND SS.LOCATION_GID = L.LOCATION_GID AND STOP_TYPE = 'D' AND STOP_NUM = ( SELECT MAX(SS1.STOP_NUM) FROM GLOGOWNER.SHIPMENT_STOP SS1 WHERE SS1.SHIPMENT_GID = S.SHIPMENT_GID))     ORIGINAL_ORDER_DELIVERY_POINT_NAME 
    -- LOCATION_REMARKS REMARK SUB QUERIES        
    , (SELECT LR.REMARK_TEXT FROM GLOGOWNER.LOCATION_REMARK LR WHERE LR.REMARK_QUAL_GID = LR.DOMAIN_NAME||'.VAT_NUMBER' AND LR.LOCATION_GID = SPL.LOCATION_GID AND ROWNUM =1)                          CARRIER_VAT_NUMBER
     -- IFF Tax Mapping
     , IIBB_CABA_AMOUNT
     , IIBB_BA_AMOUNT
     , CGST_AMOUNT
     , IGST_AMOUNT
     , SGST_AMOUNT
     , PIS_AMOUNT
     , ISS_AMOUNT
     , COFINS_AMOUNT
     , IOF_AMOUNT
     , RETENTION_AMOUNT
     , WITHHOLDING_AMOUNT
     , VATS_AMOUNT
     , IIBB_CABA_PERCENTAGE
     , IIBB_BA_PERCENTAGE
     , CGST_PERCENTAGE
     , IGST_PERCENTAGE
     , SGST_PERCENTAGE
     , PIS_PERCENTAGE
     , ISS_PERCENTAGE
     , COFINS_PERCENTAGE
     , IOF_PERCENTAGE
     , RETENTION_PERCENTAGE
     , WITHHOLDING_PERCENTAGE
     , VATS_PERCENTAGE
     , CELATON_TOTAL_COST_WITH_VAT
     , CELATON_NET_COST
    FROM
        GLOGOWNER.INVOICE                                 INV
      , GLOGOWNER.SHIPMENT                                S
      , GLOGOWNER.SHIPMENT_INVOLVED_PARTY                 SIP
      , GLOGOWNER.ORDER_RELEASE                           ORL
      , GLOGOWNER.SHIPMENT_INVOLVED_PARTY                 PID
      , GLOGOWNER.RATE_OFFERING                           RO
    --CTE TABLES 
      , FILTER_CTE                                        FCTE
      , COST_CATEGORY_CTE                                 CC
      , LOCATION_CTE                                      SL
      , LOCATION_CTE                                      DL
      , LOCATION_CTE                                      SPL
      , LOCATION_CTE                                      IPL
      , TAX_VALUES_CTE                                    TCTE
      , INVOICE_REFNUM_CTE                                IRCTE
      , COST_EVENTS_CTE                                   CECTE
      , SHIP_COST_SPLIT                                   SCCTE
      , SHIP_REFNUM_CTE                                   SRCTE

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
        AND S.SHIPMENT_GID                                = CECTE.SHIPMENT_GID
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
      OTM_SHIPMENT_NUMBER                                                                                         "OTM Shipment ID"
    , ORDER_RELEASE_ID                                                                                            "Order Release"
    , ORDER_TYPE                                                                                                  "Order Type"
    , SALES_ORG                                                                                                   "sales Org"
    , FBA_RESPONSIBILITY_STATUS                                                                                   "FBA OTM Responsibility Status"
    , BILL_TO_LEGAL_NAME                                                                                          "Bill to Legal Name"
    , BILL_TO_ADDRESS                                                                                             "Bill to Address"
    , BILL_TO_VAT_NUMBER                                                                                          "Bill to VAT Number"
    , OTM_INVOICE_ID                                                                                              "Carrier Invoice ID"
    , CARRIER_INVOICE_NUMBER                                                                                      "Carrier Invoice Number"
    , CARRIER_INVOICE_DATE                                                                                        "Carrier Invoice Date"
    , CARRIER_INVOICE_RECEIPT_DATE                                                                                "Carrier Invoice Receipt Date"
    , CARRIER_NAME                                                                                                "Carrier Name"
    , CARRIER_ADDRESS                                                                                             "Carrier Address"
    , CARRIER_VAT_NUMBER                                                                                          "Carrier VAT Number"
    , CARRIER_OTM_ID                                                                                              "Carrier OTM ID"
    , CARRIER_COUNTRY                                                                                             "Carrier Country"   
    , SHIPMENT_COLLECTION_DATE                                                                                    "Shipment Collection Date"
    , SHIPMENT_DELIVERY_DATE                                                                                      "Shipment Delivery Date"
    , COLLECTION_POINT_NAME                                                                                       "Collection Point Name"
    , COLLECTION_POINT_CITY                                                                                       "Collection Point City"
    , COLLECTION_POINT_COUNTRY                                                                                    "Collection Point Country Code"
    , COLLECTION_POINT_ID                                                                                         "Collection Point ID"
    , DELIVERY_POINT_NAME                                                                                         "Delivery Point Name"
    , DELIVERY_POINT_CITY                                                                                         "Delivery Point City"
    , DELIVERY_POINT_COUNTRY                                                                                      "Delivery Point Country code"
    , DELIVERY_POINT_ID                                                                                           "Delivery Point ID"
    , TRANSPORT_MODE                                                                                              "Mode"
    , EQUIPMENT_TYPE                                                                                              "Equipment Type"
    , LANE_ID                                                                                                     "Lane ID"
    , RATES_EFFECTIVE_FROM                                                                                        "Date Rates Effective From / Rate Version ID"
    , RATES_EFFECTIVE_TO                                                                                          "Date Rates Effective To / Rate Version ID"
    , GROSS_WEIGHT                                                                                                "Gross Weight KG"
    , TO_CHAR(ACTUAL_CHARGEABLE_WEIGHT,'FM999G999G999G990D00')                                                    "Base Actual Weight KG"
    , TO_CHAR(SHIPMENT_BASE_COST,'FM999G999G999G990D00')                                                          "OTM Shipment Freight Cost (BASE)"
    , TO_CHAR(FUEL_SURCHARGE_COST,'FM999G999G999G990D00')                                                         "OTM Shipment Fuel Surcharge Cost"
    , TO_CHAR(ROUND(DELAYS_COST, 2),'FM999G999G999G990D00')                                                       "OTM Shipment Delays total (Inc demurrage/waiting time)"
    , TO_CHAR(ROUND(CANCELLATION_CHARGE, 2),'FM999G999G999G990D00')                                               "OTM Shipment Cancellation Cost"
    , TO_CHAR(ROUND(MISCELLANEOUS, 2),'FM999G999G999G990D00')                                                     "OTM Shipment Miscellaneous Cost"
    , TO_CHAR(ROUND(SHIPMENT_ACCESSORIAL_COST,2),'FM999G999G999G990D00')                                          "OTM Shipment Freight Accessorial Cost"
    , TO_CHAR(SHIPMENT_TOTAL_ACTUAL_COST,'FM999G999G999G990D00')                                                  "OTM Shipment Total Freight Cost"
    , TO_CHAR(SHIPMENT_TOTAL_TAX,'FM999G999G999G990D00')                                                          "OTM Order / Shipment Total Tax Value"
   -- , TO_CHAR(ROUND(NVL(SHIPMENT_BASE_COST, 0) + NVL(SHIPMENT_ACCESSORIAL_COST, 0)+NVL(TOTAL_FUEL_SURCHARGE, 0) ,2),'FM999G999G999G990D00')    "OTM Order / Shipment Total Cost"
    , TO_CHAR(OTM_SHIPMENT_APPROVED_VALUE,'FM999G999G999G990D00')                                                 "OTM Shipment Approved Value"
    , TO_CHAR(OTM_SHIPMENT_ACCRUAL_VALUE,'FM999G999G999G990D00')                                                  "OTM Shipment Accrual Value"
  --, TO_CHAR(OTM_SHIPMENT_REJECTED_VALUE,'FM999G999G999G990D00')                                                 "OTM Shipment Rejected Value"
    , TO_CHAR(APPORTIONED_OTM_SHIPMENT,'FM999G999G999G990D00')                                                    "OTM Shipment Apportioned Value"
    , MASTER_RATE_CURRENCY                                                                                        "OTM Shipment Currency"
    , TO_CHAR(OTM_INVOICE_AMOUNT_NET,'FM999G999G999G990D00')                                                      "Carrier Invoice Amount(Net)"
    , TO_CHAR(INVOICE_VAT_AMOUNT,'FM999G999G999G990D00')                                                          "Carrier Invoice Total Tax Value"
    , TO_CHAR(OTM_INVOICE_AMOUNT_GROSS,'FM999G999G999G990D00')                                                    "Carrier Invoice Gross Value"
    , VATS_PERCENTAGE                                                                                             "Carrier Invoice VAT Percentage"
    , VATS_AMOUNT                                                                                                 "Carrier Invoice VAT Amount Value"
    , CGST_PERCENTAGE                                                                                             "Carrier Invoice CGST Percentage"
    , CGST_AMOUNT                                                                                                 "Carrier Invoice CGST Value"
    , IGST_PERCENTAGE                                                                                             "Carrier Invoice IGST Percentage"
    , IGST_AMOUNT                                                                                                 "Carrier Invoice IGST Value"
    , SGST_PERCENTAGE                                                                                             "Carrier Invoice SGST Percentage"
    , SGST_AMOUNT                                                                                                 "Carrier Invoice SGST Value"
    , IIBB_CABA_PERCENTAGE                                                                                        "Carrier Invoice IIBB CABA Percentage"
    , IIBB_CABA_AMOUNT                                                                                            "Carrier Invoice IIBB CABA Value"
    , IIBB_BA_PERCENTAGE                                                                                          "Carrier Invoice IIBB BA Percentage"
    , IIBB_BA_AMOUNT                                                                                              "Carrier Invoice IIBB BA Value" 
    , IOF_PERCENTAGE                                                                                              "Carrier Invoice IOF Percentage"
    , IOF_AMOUNT                                                                                                  "Carrier Invoice IOF Value"
    , PIS_PERCENTAGE                                                                                              "Carrier Invoice PIS Percentage"
    , PIS_AMOUNT                                                                                                  "Carrier Invoice PIS Value"
    , ISS_PERCENTAGE                                                                                              "Carrier Invoice ISS Percentage"
    , ISS_AMOUNT                                                                                                  "Carrier Invoice ISS Value"
    , COFINS_PERCENTAGE                                                                                           "Carrier Invoice COFINS Percentage"
    , COFINS_AMOUNT                                                                                               "Carrier Invoice COFINS Value"
    , RETENTION_PERCENTAGE                                                                                        "Carrier Invoice Retention Percentage"
    , RETENTION_AMOUNT                                                                                            "Carrier Invoice Retention Value"
    , WITHHOLDING_PERCENTAGE                                                                                      "Carrier Invoice Withholding Tax Percentage"        
    , WITHHOLDING_AMOUNT                                                                                          "Carrier Invoice Withholding Tax Value"
    , TO_CHAR(CARRIER_INVOICE_VALUE_MATCHED,'FM999G999G999G990D00')                                               "Carrier Invoice Net Value Matched against Order / Shipment Net Value"
    , OTM_INVOICE_CURRENCY                                                                                        "Carrier Invoice Shipment Currency"
    , COST_OK                                                                                                     "Cost OK Milestone"
    , TO_CHAR(COK_DATE, 'DD/MM/YYYY hh24:mi:ss')                                                                  "Cost Ok Date"
    , OTM_INVOICE_STATUS                                                                                          "OTM Invoice status"
    , INVOICE_STATUS_DATE                                                                                         "Invoice “Approved” status Date"
    , OTM_SHIPMENT_STATUS                                                                                         "Shipment Status"
    , FBA_PROCESS_MODE                                                                                            "FBA Process Mode"
    , PMER_EXCHANGE_RATE                                                                                          "PMER Exchange rate (master carrier currency to EURO)"
    , ORIGIN_COST_OK_DATE                                                                                         "Origin Cost OK Date"
    , FINAL_COST_OK_DATE                                                                                          "Final Cost OK Date"


FROM MAIN_CTE
ORDER BY  OTM_SHIPMENT_NUMBER
        , ACTUAL_CHARGEABLE_WEIGHT
        , ORDER_RELEASE_ID
        , OTM_INVOICE_ID        