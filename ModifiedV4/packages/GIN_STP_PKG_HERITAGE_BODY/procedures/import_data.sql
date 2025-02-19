PROCEDURE import_data (
      v_brn_code        IN       NUMBER,
      v_brn_sht_desc    IN       VARCHAR2,
      v_fxd_exch_rate   IN       VARCHAR2,
      v_psd_code        IN       NUMBER DEFAULT NULL,
      v_tot_rec         OUT      NUMBER,
      v_success         OUT      NUMBER
   )
   IS
      v_cnt             NUMBER;
      v_prp_code        NUMBER;
      v_sect_code       NUMBER;
      v_sect_desc       VARCHAR2 (35);
      v_pol_tab         gin_stp_pkg.policy_tab;
      v_rsk_tab         gin_stp_pkg.risk_tab;
      v_cur_code        NUMBER;
      v_cur_symbol      VARCHAR2 (35);
      v_agent_code      NUMBER;
      v_agnt_sht_desc   VARCHAR2 (35);
      v_errmsg          VARCHAR2 (400);
      v_pol_batch_no    NUMBER;

      --v_user        VARCHAR2(35):=Pkg_Global_Vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
      CURSOR cur_recs
      IS
         SELECT *
           FROM gin_pol_stp_data
          WHERE NVL (psd_transfered, 'N') != 'Y'
            AND psd_code =
                   DECODE (NVL (v_psd_code, 0),
                           0, psd_code,
                           NVL (v_psd_code, 0)
                          );
   --CURSOR cur_clnts(vpsd_agnt_client_id IN NUMBER) IS SELECT * FROM GIN_POL_STP_CLNT_DATA WHERE PSC_AGNT_CLNT_ID = vpsd_agnt_client_id;
   BEGIN
      v_tot_rec := 0;
      v_success := 0;

      FOR crecs IN cur_recs
      LOOP
         v_tot_rec := NVL (v_tot_rec, 0) + 1;

         BEGIN
            BEGIN
               SELECT COUNT (1)
                 INTO v_cnt
                 FROM gin_pol_stp_clnt_data
                WHERE psc_agnt_clnt_id = crecs.psd_agnt_client_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg := 'Error retrieving insured details..' || SQLERRM;
                  raise_application_error (-20001, v_errmsg);
            END;

            IF NVL (v_cnt, 0) = 0
            THEN
               IF crecs.psd_gis_clnt_code IS NOT NULL
               THEN
                  v_prp_code := crecs.psd_gis_clnt_code;
               ELSE
                  v_errmsg := 'Client data not provided..';
                  raise_application_error (-20001, v_errmsg);
               END IF;
            ELSIF NVL (v_cnt, 0) = 1
            THEN
               IF crecs.psd_gis_clnt_code IS NOT NULL
               THEN
                  v_prp_code := crecs.psd_gis_clnt_code;
               ELSE
                  BEGIN
                     SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'YY'))
                            || tqc_clnt_code_seq.NEXTVAL
                       INTO v_prp_code
                       FROM DUAL;

                     INSERT INTO tqc_clients
                                 (clnt_code, clnt_pin, clnt_sht_desc,
                                  clnt_postal_addrs,
                                                    --PRP_COUNTRY,
                                                    clnt_other_names,
                                  clnt_surname, clnt_id_reg_no, clnt_wef,
                                  
                                  -- PRP_DONE_BY,

                                  --PRP_TOWN,
                                  clnt_zip_code, clnt_tel, clnt_tel2,
                                  clnt_fax)
                        SELECT v_prp_code, NULL, psc_sht_desc, psc_post_add,
                               
                               --    NVL(PSC_COUNTRY,'KENYA'),
                               psc_other_names, psc_surname, NULL,
                               TRUNC (SYSDATE),                      --v_user,
                                               --PSC_TOWN,
                                               psc_postal_code, psc_tel1,
                               psc_tel2, psc_fax
                          FROM gin_pol_stp_clnt_data
                         WHERE psc_agnt_clnt_id = crecs.psd_agnt_client_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg := 'Error creating the client..' || SQLERRM;
                        raise_application_error (-20001, v_errmsg);
                  END;
               END IF;
            ELSIF NVL (v_cnt, 0) > 1
            THEN
               v_errmsg := 'More than one record for Client provided..';
               raise_application_error (-20001, v_errmsg);
            END IF;

            BEGIN
               SELECT agn_code, agn_sht_desc
                 INTO v_agent_code, v_agnt_sht_desc
                 FROM tqc_agencies
                WHERE agn_code = 0;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                         'Error getting Direct Business defaults.' || SQLERRM;
                  raise_application_error (-20001, v_errmsg);
            END;

            BEGIN
               SELECT cur_code, cur_symbol
                 INTO v_cur_code, v_cur_symbol
                 FROM tqc_currencies
                WHERE cur_symbol = crecs.psd_currency;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                             'Error determining currency defined.' || SQLERRM;
                  raise_application_error (-20001, v_errmsg);
            END;

            BEGIN
               v_pol_tab (1).pol_policy_no := crecs.psd_agnt_policy_id;
               v_pol_tab (1).pol_endos_no := NULL;
               v_pol_tab (1).pol_batch_no := NULL;
               v_pol_tab (1).pol_agnt_agent_code := v_agent_code;
               v_pol_tab (1).pol_agnt_sht_desc := v_agnt_sht_desc;
               v_pol_tab (1).pol_bind_code := NULL;
               v_pol_tab (1).pol_wef_dt :=
                                        TO_DATE (crecs.psd_wef, 'DD/MM/RRRR');
               --crecs.PSD_WEF;
               v_pol_tab (1).pol_wet_dt :=
                                        TO_DATE (crecs.psd_wet, 'DD/MM/RRRR');
               --crecs.PSD_WET;
               v_pol_tab (1).pol_status := 'NB';
               v_pol_tab (1).pol_cur_code := v_cur_code;
               v_pol_tab (1).pol_policy_type := 'N';
               v_pol_tab (1).pol_brn_code := v_brn_code;
               v_pol_tab (1).pol_cur_rate := crecs.psd_exch_rate;
               v_pol_tab (1).pol_coinsurance := 'N';
               v_pol_tab (1).pol_coinsure_leader := NULL;
               v_pol_tab (1).pol_cur_symbol := v_cur_symbol;
               v_pol_tab (1).pol_brn_sht_desc := v_brn_sht_desc;
               v_pol_tab (1).pol_prp_code := v_prp_code;
               v_pol_tab (1).pol_pro_code := crecs.psd_pro_code;
               v_pol_tab (1).pol_your_ref := 'Web data';
               v_pol_tab (1).pol_prop_holding_co_prp_code := NULL;
               v_pol_tab (1).pol_oth_int_parties := NULL;
               v_pol_tab (1).pol_pro_sht_desc := crecs.psd_product;
               v_pol_tab (1).pol_binder_policy := 'N';
               v_pol_tab (1).pol_coinsurance_share := NULL;
               v_pol_tab (1).pol_ri_agent_comm_rate := NULL;
               v_pol_tab (1).pol_ri_agnt_sht_desc := NULL;
               v_pol_tab (1).pol_ri_agnt_agent_code := NULL;
               v_pol_tab (1).pol_policy_doc := NULL;
               v_pol_tab (1).pol_commission_allowed := 'N';
               --v_pol_tab(1).POL_INTRO_CODE := NULL;
               v_pol_tab (1).pol_renewable := 'Y';
               v_pol_tab (1).pol_short_period := 'N';
            --v_pol_tab(1).POL_EXCH_RATE_FIXED := v_fxd_exch_rate;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg := 'Error assigning data imported' || SQLERRM;
                  raise_application_error (-20001, v_errmsg);
            END;

            BEGIN
               SELECT bets_sect_code, sect_sht_desc
                 INTO v_sect_code, v_sect_desc
                 FROM gin_bndr_excl_temp_sects,
                      gin_sections,
                      gin_subcl_sections
                WHERE bets_sect_code = sect_code
                  AND sec_sect_code = sect_code
                  AND sec_scl_code = crecs.psd_scl_code
                  AND bets_scl_code = crecs.psd_scl_code
                  AND bets_covt_code = crecs.psd_cvt_code
                  AND bets_bind_code = crecs.psd_bind_code
                  AND bets_excl_tmp_col = 1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Section mapping not defined for this subclass..'
                     || SQLERRM;
                  raise_application_error (-20001, v_errmsg);
            END;

            BEGIN
               v_rsk_tab (1).ipu_property_id := crecs.psd_property_id;
               v_rsk_tab (1).ipu_desc := crecs.psd_risk_desc;
               v_rsk_tab (1).ipu_scl_code := crecs.psd_scl_code;
               v_rsk_tab (1).ipu_scl_desc := crecs.psd_class;
               v_rsk_tab (1).ipu_cvt_code := crecs.psd_cvt_code;
               v_rsk_tab (1).ipu_cvt_desc := crecs.psd_cvt_sht_desc;
               v_rsk_tab (1).ipu_bind_code := crecs.psd_bind_code;
               v_rsk_tab (1).ipu_bind_desc := crecs.psd_binder;
               v_rsk_tab (1).ipu_sect_code := v_sect_code;
               v_rsk_tab (1).ipu_sect_desc := v_sect_desc;
               v_rsk_tab (1).ipu_limit := crecs.psd_si;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg := 'Error assigning data imported' || SQLERRM;
                  raise_application_error (-20001, v_errmsg);
            END;

            v_success := NVL (v_success, 0) + 1;

            UPDATE gin_pol_stp_data
               SET psd_transfered = 'Y',
                   psd_not_trnsf_reason = NULL,
                   psd_pol_batch_no = v_pol_batch_no
             WHERE psd_code = crecs.psd_code;
         --COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg;
               ROLLBACK;

               UPDATE gin_pol_stp_data
                  SET psd_transfered = 'N',
                      psd_not_trnsf_reason = v_errmsg
                WHERE psd_code = crecs.psd_code;
         -- COMMIT;
         END;
      END LOOP;
   END;