SET serveroutput ON;

/* Create Function to convert HIGH_VALUE into Date format */
/* Change the to_date format according to partition column datatype*/

CREATE OR REPLACE FUNCTION GET_HIGH_VALUE_AS_DATE (
    p_TableOwner     IN VARCHAR2,
    p_TableName      IN VARCHAR2,
    p_PartitionName  IN VARCHAR2
) RETURN DATE
authid current_user IS
   v_LongVal LONG;

BEGIN
    SELECT high_value INTO v_LongVal
      FROM SYS.all_tab_partitions
     WHERE table_name = p_TableName
       AND partition_name = p_PartitionName
       and table_owner = p_TableOwner;

    RETURN TO_DATE(substr(v_LongVal, 11, 19), 'YYYY-MM-DD HH24:MI:SS');

END GET_HIGH_VALUE_AS_DATE;
/


/* PL/SQL Block to drop partition older than minimum required date*/



DECLARE
  last_timing INTEGER := NULL;
BEGIN
  FOR VAR IN
  (SELECT TABLE_OWNER,
    TABLE_NAME,
    PARTITION_NAME ,
    HIGH_VALUE
  FROM DBA_TAB_PARTITIONS
  WHERE TABLE_NAME                                                                       = 'TABLE_NAME'
  AND TABLE_OWNER                                                                        ='TABLE_OWNER'
  AND interval                                                                          <> 'NO'
  AND TO_CHAR(GET_HIGH_VALUE_AS_DATE(TABLE_OWNER,TABLE_NAME, PARTITION_NAME),'YYYYMMDD') < '20121231' -- Pass your minimum date here
  ORDER BY PARTITION_POSITION
  )
  LOOP
    LAST_TIMING := DBMS_UTILITY.GET_TIME;
    EXECUTE immediate 'ALTER TABLE ' || VAR.TABLE_OWNER || '.' || VAR.TABLE_NAME || ' DROP PARTITION ' || VAR.PARTITION_NAME||' update indexes parallel 2';
    DBMS_OUTPUT.PUT_LINE('Table ' || VAR.TABLE_OWNER || '.' || VAR.TABLE_NAME || ' partition ' || VAR.PARTITION_NAME||' with high value '|| VAR. HIGH_VALUE ||' has been dropped - '||(DBMS_UTILITY.GET_TIME - LAST_TIMING)/100||' seconds.');
  END LOOP;
END;
