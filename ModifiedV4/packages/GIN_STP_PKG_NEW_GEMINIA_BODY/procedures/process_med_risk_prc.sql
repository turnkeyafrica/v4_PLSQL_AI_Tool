PROCEDURE process_med_risk_prc (v_pol_batch_no   IN NUMBER,
                                    v_comm_rate      IN NUMBER,
                                    v_trans_type     IN VARCHAR2,
                                    v_scl1           IN VARCHAR2,
                                    v_scl2           IN VARCHAR2,
                                    v_scl3           IN VARCHAR2,
                                    v_scl4           IN VARCHAR2,
                                    v_scl5           IN VARCHAR2,
                                    v_scl6           IN VARCHAR2,
                                    v_prem1          IN NUMBER,
                                    v_prem2          IN NUMBER,
                                    v_prem3          IN NUMBER,
                                    v_prem4          IN NUMBER,
                                    v_prem5          IN NUMBER,
                                    v_prem6          IN NUMBER)
    IS
        v_insert          BOOLEAN := FALSE;
        v_scl_code        NUMBER;
        v_prem            NUMBER (23, 5);
        v_covt_type       VARCHAR2 (30);
        v_covt_code       NUMBER;
        v_si              NUMBER;
        v_rsk_rec         web_risk_tab := web_risk_tab ();
        v_rsk_sect_data   web_sect_tab := web_sect_tab ();
        r_no              NUMBER := 0;
        v_med_scl         VARCHAR2 (10);
        v_scl_desc        VARCHAR2 (50);
        v_date_from       DATE;
        v_date_to         DATE;
        v_prp_code        NUMBER;
        v_med_policy_no   VARCHAR2 (30);
        v_bind_code       NUMBER;
        v_user            VARCHAR2 (30);
        v_new_ipu_code    NUMBER;
        v_sect_code       NUMBER;
    BEGIN
        FOR x IN 1 .. 6
        LOOP
            v_insert := FALSE;

            IF x = 1 AND v_scl1 IS NOT NULL AND NVL (v_prem1, 0) != 0
            THEN
                BEGIN
                    SELECT scm_scl_code
                      INTO v_scl_code
                      FROM gin_subclass_mapping
                     WHERE scm_mapped_code = v_scl1;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error Fetching Sub Class Mapping For ' || v_scl1);
                END;

                v_insert := TRUE;
                v_prem := NVL (v_prem1, 0);
                v_med_scl := v_scl1;
            ELSIF x = 2 AND v_scl2 IS NOT NULL AND NVL (v_prem2, 0) != 0
            THEN
                BEGIN
                    SELECT scm_scl_code
                      INTO v_scl_code
                      FROM gin_subclass_mapping
                     WHERE scm_mapped_code = v_scl2;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error Fetching Sub Class Mapping For ' || v_scl2);
                END;

                v_insert := TRUE;
                v_prem := NVL (v_prem2, 0);
                v_med_scl := v_scl3;
            ELSIF x = 3 AND v_scl3 IS NOT NULL AND NVL (v_prem3, 0) != 0
            THEN
                BEGIN
                    SELECT scm_scl_code
                      INTO v_scl_code
                      FROM gin_subclass_mapping
                     WHERE scm_mapped_code = v_scl3;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error Fetching Sub Class Mapping For ' || v_scl3);
                END;

                v_insert := TRUE;
                v_prem := NVL (v_prem3, 0);
                v_med_scl := v_scl3;
            ELSIF x = 4 AND v_scl4 IS NOT NULL AND NVL (v_prem4, 0) != 0
            THEN
                BEGIN
                    SELECT scm_scl_code
                      INTO v_scl_code
                      FROM gin_subclass_mapping
                     WHERE scm_mapped_code = v_scl4;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error Fetching Sub Class Mapping For ' || v_scl4);
                END;

                v_insert := TRUE;
                v_prem := NVL (v_prem4, 0);
                v_med_scl := v_scl4;
            ELSIF x = 5 AND v_scl5 IS NOT NULL AND NVL (v_prem5, 0) != 0
            THEN
                BEGIN
                    SELECT scm_scl_code
                      INTO v_scl_code
                      FROM gin_subclass_mapping
                     WHERE scm_mapped_code = v_scl5;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error Fetching Sub Class Mapping For ' || v_scl5);
                END;

                v_insert := TRUE;
                v_prem := NVL (v_prem5, 0);
                v_med_scl := v_scl5;
            ELSIF x = 6 AND v_scl6 IS NOT NULL AND NVL (v_prem6, 0) != 0
            THEN
                BEGIN
                    SELECT scm_scl_code
                      INTO v_scl_code
                      FROM gin_subclass_mapping
                     WHERE scm_mapped_code = v_scl6;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error Fetching Sub Class Mapping For ' || v_scl6);
                END;

                v_insert := TRUE;
                v_prem := NVL (v_prem6, 0);
                v_med_scl := v_scl6;
            END IF;

            IF v_insert
            THEN
                BEGIN
                    SELECT sclcovt_covt_sht_desc,
                           sclcovt_covt_code,
                           sclcovt_default_si,
                           scl_desc
                      INTO v_covt_type,
                           v_covt_code,
                           v_si,
                           v_scl_desc
                      FROM gin_subclass_cover_types, gin_sub_classes
                     WHERE     scl_code = sclcovt_scl_code
                           AND scl_code = v_scl_code
                           AND NVL (sclcovt_default, 'N') = 'Y';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                               'Unable retrieving subclass cover type for subclass code '
                            || v_scl_code);
                END;

                BEGIN
                    SELECT pol_policy_cover_from,
                           pol_policy_cover_to,
                           pol_prp_code,
                           pol_old_policy_number,
                           pol_prepared_by
                      INTO v_date_from,
                           v_date_to,
                           v_prp_code,
                           v_med_policy_no,
                           v_user
                      FROM gin_policies
                     WHERE pol_batch_no = v_pol_batch_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error fetching policy number (medware...)');
                END;

                IF NVL (v_comm_rate, 0) = 0
                THEN
                    UPDATE gin_policies
                       SET pol_commission_allowed = 'N'
                     WHERE     pol_batch_no = v_pol_batch_no
                           AND pol_agnt_agent_code != 0;
                END IF;

                BEGIN
                    SELECT bind_code
                      INTO v_bind_code
                      FROM gin_binders
                     WHERE     bind_scl_code = v_scl_code
                           AND NVL (bind_web_default, 'N') = 'Y';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                               'Error fetching binder for sub class '
                            || v_scl_code);
                END;

                --            IF v_trans_type = 'NB' THEN
                --create the insured
                --create the risks
                r_no := 1;
                v_rsk_rec := web_risk_tab ();
                v_rsk_rec.EXTEND (r_no);
                v_rsk_rec (r_no) :=
                    web_risk_rec (v_med_policy_no || '-' || v_med_scl,
                                  --IPU_PROPERTY_ID  VARCHAR2(60),
                                  v_scl_desc, --  IPU_DESC         VARCHAR2(200),
                                  v_scl_code,     --  IPU_SCL_CODE     NUMBER,
                                  NULL,     --  IPU_SCL_DESC     VARCHAR2(55),
                                  v_covt_code,    --  IPU_CVT_CODE     NUMBER,
                                  v_covt_type, --  IPU_CVT_DESC     VARCHAR2(20),
                                  v_bind_code,    --  IPU_BIND_CODE    NUMBER,
                                  NULL,     --  IPU_BIND_DESC    VARCHAR2(45),
                                  NULL,     --  IPU_SECT_CODE    VARCHAR2(60),
                                  NULL,     --  IPU_SECT_DESC    VARCHAR2(60),
                                  v_si,     --  IPU_LIMIT        NUMBER(22,5),
                                  NULL,       --  WEB_IPU_CODE     NUMBER(22),
                                  NULL,      --  IPU_ACTION_TYPE  VARCHAR2(1),
                                  NULL,       --  GIS_IPU_CODE     NUMBER(22),
                                  NULL,           --  POLIN_CODE       NUMBER,
                                  v_prp_code,     --  prp_code         NUMBER,
                                  NULL,      --  IPU_STATUS       VARCHAR2(3),
                                  NULL,      --IPU_EML_SI         VARCHAR2(1),
                                  NULL,    --IPU_RISK_ADDRESS   VARCHAR2(150),
                                  NULL,    --IPU_RISK_DETAILS   VARCHAR2(150),
                                  'Y',       --IPU_PRORATA        VARCHAR2(1),
                                  NULL,     --IPU_NCD_STATUS     VARCHAR2(15),
                                  NULL,           --IPU_NCD_LVL        NUMBER,
                                  NULL,           --IPU_QUZ_CODE       NUMBER,
                                  NULL,           --IPU_RELR_CODE      NUMBER,
                                  NULL,     --IPU_RELR_SHT_DESC  VARCHAR2(15),
                                  NULL,      --IPU_RETRO_COVER    VARCHAR2(1),
                                  NULL,             --IPU_RETRO_WEF      DATE,
                                  NULL,           --IPU_TERR_CODE      NUMBER,
                                  NULL,    --IPU_TERR_DESC      VARCHAR2(200),
                                  NULL,           --IPU_RC_CODE        NUMBER,
                                  NULL,     --IPU_RC_SHT_DESC    VARCHAR2(20),
                                  NULL,      --IPU_FREE_LIMIT     VARCHAR2(1),
                                  NULL,             --IPU_SURVEY_DATE    DATE,
                                  NULL,           --IPU_PRO_CODE       NUMBER,
                                  NULL,     --IPU_PRO_SHT_DESC   VARCHAR2(55),
                                  'A',          --IPU_ADD_EDIT    VARCHAR2(2),
                                  v_date_from,
                                  --TO_DATE(TO_CHAR(cur_clnts_rec.PED_WEF,'DD-MON-RRRR'),'DD/MM/RRRR'),                         --IPU_WEF         DATE,
                                  v_date_to,
                                  -- TO_DATE(TO_CHAR(cur_clnts_rec.PED_WET,'DD-MON-RRRR'),'DD/MM/RRRR'),                         --IPU_WET         DATE,
                                  NULL,        --IPU_CERT_TYPE   VARCHAR2(10),
                                  NULL,                --IPU_CERT_WEF    DATE,
                                  NULL,                 --IPU_CERT_WET    DATE
                                  v_comm_rate,                 --IPU_COMM_RATE
                                  v_prem,                             --IPU_FP
                                  v_si,
                                  'N',  --DECODE(NVL(v_max_expo,0),0,'Y','N'),
                                  NULL,                 --IPU_AGN_CODE NUMBER,
                                  NULL,       --IPU_AGN_SHT_DESC VARCHAR2(55),
                                  NULL,        --IPU_QP_BIND_TYPE VARCHAR2(1),
                                  NULL,              --IPU_QP_BIND_CODE NUMBER
                                  NULL,              --IPU_CONVEYANCE VARCHAR2
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,                --ipu_endorse_fap_or_bc
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL);

                BEGIN
                    gin_stp_pkg.gin_ipu_prc (v_pol_batch_no,
                                             v_trans_type,
                                             'A',
                                             v_rsk_rec,
                                             v_user,
                                             v_new_ipu_code,
                                             'N',
                                             'Y',
                                             NULL);
                END;

                --create the sections
                BEGIN
                    SELECT scvts_sect_code
                      INTO v_sect_code
                      FROM gin_subcl_covt_sections
                     WHERE     scvts_scl_code = v_scl_code
                           AND scvts_covt_code = v_covt_code
                           AND NVL (scvts_mandatory, 'N') = 'Y';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                               'Error fetching medware default section for sub class '
                            || v_scl_code);
                END;

                gin_rsk_limits_stp (v_new_ipu_code,
                                    --v_new_ipu_code   IN   NUMBER,
                                    v_scl_code, --v_scl_code       IN   NUMBER,
                                    v_bind_code, --v_bind_code      IN   NUMBER,
                                    v_sect_code, --v_sect_code      IN   NUMBER,
                                    v_covt_code, --v_covt_code      IN   NUMBER,
                                    1,         --v_row            IN   NUMBER,
                                    NULL,
                                    'A',     --v_add_edit       IN   VARCHAR2,
                                    'N',     --v_renewal        IN   VARCHAR2,
                                    NULL        --v_ncd_level      IN   NUMBER
                                        );
            --            ELSIF v_trans_type = 'EN' THEN
            --            -- populate the risks based on the subclasses provided
            --            null;
            --            ELSIF v_trans_type = 'RN' THEN
            --            -- populate the risks based on the provided subclasses
            --            null;
            --            END IF;
            END IF;
        END LOOP;
    END;