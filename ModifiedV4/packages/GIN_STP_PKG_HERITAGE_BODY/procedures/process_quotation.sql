PROCEDURE process_quotation (
         vpol_id      IN       NUMBER,
         v_quo_code   IN OUT   NUMBER,
         v_quo_no     IN OUT   VARCHAR2
      )
      IS
         v_exp_flag         VARCHAR2 (2);
         v_open_cover       VARCHAR2 (2);
         v_user             VARCHAR2 (35)
               := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
         v_row              NUMBER        := 0;
         v_wet_date         DATE;
         v_pol_renewal_dt   DATE;
         v_cur_rate         NUMBER;
         v_cur_code         NUMBER;
         v_cur_symbol       VARCHAR2 (15);
         v_pro_sht_desc     VARCHAR2 (25);
         v_pol_uwyr         NUMBER;
         v_qno              NUMBER;
         v_qp_code          NUMBER;
         v_qr_code          NUMBER;
         v_prp_sht_desc     VARCHAR2 (35);
         v_brn_code         NUMBER;
         v_bind_code        NUMBER;
         v_bind_name        VARCHAR2 (35);
         v_rsk_sect_data    rsk_sect_tab;

         CURSOR pol_cur
         IS
            SELECT *
              FROM gin_web_policies, gin_web_risks
             WHERE pol_id = vpol_id AND ipu_pol_id = pol_id;

         CURSOR risk_cur
         IS
            SELECT *
              FROM gin_web_risks
             WHERE ipu_pol_id = vpol_id;

         CURSOR sect_cur (v_ipu_code IN NUMBER)
         IS
            SELECT *
              FROM gin_web_risk_sections
             WHERE pil_ipu_code = v_ipu_code;
      BEGIN
         DBMS_OUTPUT.put_line (5555555);
         DBMS_OUTPUT.put_line (2);

         FOR pol_rec IN pol_cur
         LOOP
            IF pol_rec.ipu_pro_code IS NULL
            THEN
               raise_error ('SELECT THE POLICY PRODUCT ...');
            END IF;

            IF pol_rec.pol_wef_dt IS NULL
            THEN
               raise_error ('PROVIDE THE COVER FROM DATE ...');
            END IF;

            DBMS_OUTPUT.put_line (21);
            v_wet_date := pol_rec.pol_wet_dt;

            IF v_wet_date IS NULL
            THEN
               v_wet_date :=
                         get_wet_date (pol_rec.pol_pro_code, pol_rec.pol_wef_dt);
            END IF;

            DBMS_OUTPUT.put_line (22);

            IF v_wet_date IS NULL
            THEN
               raise_error ('PROVIDE THE COVER TO DATE ...');
            END IF;

            DBMS_OUTPUT.put_line (23);

            IF     NVL (pol_rec.pol_binder_policy, 'N') = 'Y'
               AND pol_rec.pol_bind_code IS NULL
            THEN
               raise_error ('YOU HAVE NOT DEFINED THE BORDEREAUX CODE ..');
            END IF;

            DBMS_OUTPUT.put_line (pol_rec.pol_wef_dt);
            DBMS_OUTPUT.put_line (TO_CHAR (pol_rec.pol_wef_dt));
            DBMS_OUTPUT.put_line (TO_NUMBER (TO_CHAR (pol_rec.pol_wef_dt, 'RRRR'))
                                 );
            v_pol_uwyr := TO_NUMBER (TO_CHAR (pol_rec.pol_wef_dt, 'RRRR'));
   --         IF pol_rec.POL_UW_YEAR IS NULL OR pol_rec.POL_UW_YEAR = 0 THEN
   --             RAISE_ERROR('THE UNDERWRITING YEAR MUST BE A VALID YEAR...');
   --         END IF;
            DBMS_OUTPUT.put_line (25);
            v_pol_renewal_dt :=
                              get_renewal_date (pol_rec.pol_pro_code, v_wet_date);

            IF NVL (pol_rec.pol_add_edit, 'A') = 'A'
            THEN
               BEGIN
                  SELECT TO_NUMBER (   TO_CHAR (SYSDATE, 'RRRR')
                                    || gin_quot_code_seq.NEXTVAL
                                   )
                    INTO v_quo_code
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error
                        ('Unable to generate new quotation sequence GIN_QUOT_CODE_SEQ.NEXTVAL, ...'
                        );
               END;

               BEGIN
                  SELECT TO_NUMBER (TO_CHAR (gin_quot_no_seq.NEXTVAL) || '00')
                    INTO v_qno
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error ('Unable to generate new quotation number, ...');
               END;

               v_quo_no := v_qno;
            END IF;

            v_cur_code := pol_rec.pol_cur_code;
            v_cur_rate := pol_rec.pol_cur_rate;

            IF v_cur_code IS NULL
            THEN
               v_cur_rate := NULL;

               BEGIN
                  SELECT org_cur_code, cur_symbol
                    INTO v_cur_code, v_cur_symbol
                    FROM tqc_organizations, tqc_systems, tqc_currencies
                   WHERE org_code = sys_org_code
                     AND org_cur_code = cur_code
                     AND sys_code = 37;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error ('UNABLE TO RETRIEVE THE BASE CURRENCY');
               END;

               IF v_cur_code IS NULL
               THEN
                  raise_error
                     ('THE BASE CURRENCY HAS NOT BEEN DEDFINED. CANNOT PROCEED.');
               END IF;
            ELSE
               SELECT cur_code, cur_symbol
                 INTO v_cur_code, v_cur_symbol
                 FROM tqc_currencies
                WHERE cur_code = v_cur_code;
            END IF;

            IF v_cur_rate IS NULL
            THEN
               v_cur_rate :=
                            get_exchange_rate (v_cur_code, pol_rec.pol_cur_code);
            END IF;

            IF pol_rec.pol_brn_code IS NULL
            THEN
               SELECT brn_code                                   --, BRN_SHT_DESC
                 INTO v_brn_code                                --,v_brn_sht_desc
                 FROM tqc_organizations, tqc_branches, tqc_systems
                WHERE org_web_brn_code = brn_code
                  AND org_code = sys_org_code
                  AND sys_code = 37;
            ELSE
               v_brn_code := pol_rec.pol_brn_code;
            END IF;

            IF NVL (pol_rec.pol_add_edit, 'A') = 'A'
            THEN
               BEGIN
                  INSERT INTO gin_quotations
                              (quot_code, quot_no, quot_revision_no, quot_date,
                               quot_status, quot_prepared_by, quot_cur_code,
                               quot_cur_symbol, quot_prp_code,
                               quot_agnt_agent_code,
                               quot_agnt_sht_desc, quot_brn_code,
                               quot_cover_from, quot_cover_to,
                               quot_expiry_date
                              )
                       VALUES (v_quo_code, v_qno, 0, SYSDATE,
                               'Draft', v_user, v_cur_code,
                               v_cur_symbol, pol_rec.pol_prp_code,
                               pol_rec.pol_agnt_agent_code,
                               pol_rec.pol_agnt_sht_desc, pol_rec.pol_brn_code,
                               pol_rec.pol_wef_dt, pol_rec.pol_wet_dt,
                               TRUNC (SYSDATE) + 90
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error ('Unable to create new quotation details, ...');
               END;
            ELSIF NVL (pol_rec.pol_add_edit, 'A') = 'E'
            THEN
               --RAISE_ERROR(pol_rec.POL_WEF_DT||'='||v_quo_code);
               v_quo_code := pol_rec.pol_batch_no;
               v_qno := pol_rec.pol_gis_policy_no;

               BEGIN
                  UPDATE gin_quotations
                     SET quot_prepared_by = v_user,
                         quot_cur_code = v_cur_code,
                         quot_cur_symbol = v_cur_symbol,
                         quot_prp_code = pol_rec.pol_prp_code,
                         quot_agnt_agent_code = pol_rec.pol_agnt_agent_code,
                         quot_agnt_sht_desc = pol_rec.pol_agnt_sht_desc,
                         quot_brn_code = pol_rec.pol_brn_code,
                         quot_cover_from = pol_rec.pol_wef_dt,
                         quot_cover_to = pol_rec.pol_wet_dt,
                         quot_expiry_date = TRUNC (SYSDATE) + 90
                   WHERE quot_code = v_quo_code;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error ('Error editing quotation..');
               END;
            ELSIF NVL (pol_rec.pol_add_edit, 'A') = 'D'
            THEN
               BEGIN
                  del_quotation (v_quo_code);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error ('Error deleting quotation');
               END;
            END IF;

            BEGIN
               pop_quot_taxes (v_quo_code);
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('Error updating taxes..');
            END;

            v_prp_sht_desc := pol_rec.pol_prp_sht_desc;

            IF v_prp_sht_desc IS NULL
            THEN
               BEGIN
                  SELECT clnt_sht_desc
                    INTO v_prp_sht_desc
                    FROM tqc_clients
                   WHERE clnt_code = pol_rec.pol_prp_code;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error ('Error getting insured_details..');
               END;
            END IF;

            FOR risk_rec IN risk_cur
            LOOP
               BEGIN
                  SELECT pro_sht_desc, NVL (pro_expiry_period, 'Y'),
                         NVL (pro_open_cover, 'N')
                    INTO v_pro_sht_desc, v_exp_flag,
                         v_open_cover
                    FROM gin_products
                   WHERE pro_code = risk_rec.ipu_pro_code;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error ('ERROR SECURING OPEN COVER STATUS..');
               END;

               BEGIN
                  SELECT qp_code
                    INTO v_qp_code
                    FROM gin_quot_products
                   WHERE qp_quot_code = v_quo_code
                     AND qp_pro_code = risk_rec.ipu_pro_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_qp_code := NULL;
                  WHEN OTHERS
                  THEN
                     raise_error ('Error getting product details..');
               END;

               IF v_qp_code IS NULL
               THEN
                  BEGIN
                     SELECT gin_qp_code_seq.NEXTVAL
                       INTO v_qp_code
                       FROM DUAL;

                     INSERT INTO gin_quot_products
                                 (qp_code, qp_pro_code,
                                  qp_pro_sht_desc, qp_wef_date,
                                  qp_wet_date, qp_quot_code, qp_quot_no,
                                  qp_quot_revision_no
                                 )
                          VALUES (v_qp_code, risk_rec.ipu_pro_code,
                                  risk_rec.ipu_pro_sht_desc, pol_rec.pol_wef_dt,
                                  pol_rec.pol_wet_dt, v_quo_code, v_qno,
                                  0
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        raise_error ('Error creating quotation product record..');
                  END;
               ELSE
                  BEGIN
                     UPDATE    gin_quot_products
                           SET qp_pro_code = risk_rec.ipu_pro_code,
                               qp_pro_sht_desc = risk_rec.ipu_pro_sht_desc,
                               qp_wef_date = pol_rec.pol_wef_dt,
                               qp_wet_date = pol_rec.pol_wet_dt
                         WHERE qp_quot_code = v_quo_code
                     RETURNING qp_code
                          INTO v_qp_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        raise_error ('Error editing  quotation products..');
                  END;
               END IF;

               IF risk_rec.ipu_bind_code IS NULL
               THEN
                  BEGIN
                     SELECT DISTINCT bets_bind_code, bind_name
                                INTO v_bind_code, v_bind_name
                                FROM gin_bndr_excl_temp_sects, gin_binders
                               WHERE bets_bind_code = bind_code
                                 AND bets_scl_code = risk_rec.ipu_scl_code
                                 AND bets_covt_code = risk_rec.ipu_cvt_code
                                 AND bind_agnt_agent_code =
                                                      pol_rec.pol_agnt_agent_code;
                  EXCEPTION
                     WHEN TOO_MANY_ROWS
                     THEN
                        raise_error
                           ('More than one binder defined for this class and cover type.'
                           );
                     WHEN OTHERS
                     THEN
                        raise_error
                           ('Error getting default web binder for this sub class.'
                           );
                  END;
               ELSE
                  v_bind_code := risk_rec.ipu_bind_code;
                  v_bind_name := risk_rec.ipu_bind_desc;
               END IF;

               --RAISE_ERROR(
               IF NVL (risk_rec.ipu_add_edit, 'A') = 'A'
               THEN
                  BEGIN
                     SELECT gin_qr_code_seq.NEXTVAL
                       INTO v_qr_code
                       FROM DUAL;

                     INSERT INTO gin_quot_risks
                                 (qr_code, qr_quot_code, qr_quot_no,
                                  qr_quot_revision_no, qr_property_id,
                                  qr_item_desc, qr_qty, qr_value,
                                  qr_scl_code, qr_qp_code,
                                  qr_covt_code, qr_covt_sht_desc,
                                  qr_premium, qr_bind_code, qr_wef,
                                  qr_wet, qr_ncd_level, qr_com_rate,
                                  qr_comm_amt, qr_prp_code, qr_prp_sht_desc,
                                  qr_annual_prem, qr_cover_days, qr_comment
                                 )
                          VALUES (v_qr_code, v_quo_code, v_qno,
                                  0, risk_rec.ipu_property_id,
                                  risk_rec.ipu_desc, NULL, NULL,
                                  risk_rec.ipu_scl_code, v_qp_code,
                                  risk_rec.ipu_cvt_code, risk_rec.ipu_cvt_desc,
                                  NULL, v_bind_code, pol_rec.pol_wef_dt,
                                  pol_rec.pol_wet_dt, 0, NULL,
                                  NULL, pol_rec.pol_prp_code, v_prp_sht_desc,
                                  NULL, NULL, NULL
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        raise_error ('Error insert quotation risks.');
                  END;
               ELSIF NVL (risk_rec.ipu_add_edit, 'A') = 'E'
               THEN
                  BEGIN
                     UPDATE gin_quot_risks
                        SET qr_property_id = risk_rec.ipu_property_id,
                            qr_item_desc = risk_rec.ipu_desc,
                            qr_scl_code = risk_rec.ipu_scl_code,
                            qr_covt_code = risk_rec.ipu_cvt_code,
                            qr_covt_sht_desc = risk_rec.ipu_cvt_desc,
                            qr_bind_code = v_bind_code,
                            qr_wef = pol_rec.pol_wef_dt,
                            qr_wet = pol_rec.pol_wet_dt,
                            qr_prp_code = pol_rec.pol_prp_code,
                            qr_prp_sht_desc = v_prp_sht_desc
                      WHERE qr_quot_code = v_quo_code
                        AND qr_code = risk_rec.gis_ipu_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        raise_error ('Error insert quotation risks.');
                  END;
               ELSIF NVL (risk_rec.ipu_add_edit, 'A') = 'D'
               THEN
                  BEGIN
                     del_quot_risks (risk_rec.gis_ipu_code);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        raise_error ('Error deleting risk.');
                  END;
               END IF;

               IF NVL (risk_rec.ipu_add_edit, 'A') != 'D'
               THEN
                  v_row := 0;

                  FOR sect_rec IN sect_cur (risk_rec.ipu_code)
                  LOOP
                     v_row := NVL (v_row, 0) + 1;
                     v_rsk_sect_data (1).pil_calc_group :=
                                                         sect_rec.pil_calc_group;
                     v_rsk_sect_data (1).pil_limit_amt := sect_rec.pil_limit_amt;
                     v_rsk_sect_data (1).pil_prem_rate := sect_rec.pil_prem_rate;
                     v_rsk_sect_data (1).pil_prem_amt := sect_rec.pil_prem_amt;
                     v_rsk_sect_data (1).pil_comment := sect_rec.pil_comment;
                     v_rsk_sect_data (1).pil_multiplier_rate :=
                                                    sect_rec.pil_multiplier_rate;
                     v_rsk_sect_data (1).pil_multiplier_div_factor :=
                                              sect_rec.pil_multiplier_div_factor;
                     v_rsk_sect_data (1).pil_rate_div_fact :=
                                                      sect_rec.pil_rate_div_fact;
                     v_rsk_sect_data (1).pil_compute := sect_rec.pil_compute;
                     v_rsk_sect_data (1).pil_dual_basis :=
                                                         sect_rec.pil_dual_basis;
                     v_rsk_sect_data (1).pil_declaration_section :=
                                                sect_rec.pil_declaration_section;
                     v_rsk_sect_data (1).pil_free_limit_amt :=
                                                     sect_rec.pil_free_limit_amt;
                     v_rsk_sect_data (1).pil_limit_prd := sect_rec.pil_limit_prd;

                     BEGIN
                        process_quot_rsk_limits (v_qr_code,
                                                 v_qp_code,
                                                 v_quo_code,
                                                 risk_rec.ipu_pro_code,
                                                 risk_rec.ipu_scl_code,
                                                 v_bind_code,
                                                 sect_rec.pil_sect_code,
                                                 sect_rec.pil_limit_amt,
                                                 v_row,
                                                 NVL (risk_rec.ipu_add_edit, 'A'),
                                                 v_rsk_sect_data
                                                );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           raise_error ('ERROR UPDATING RISK SECTIONS..');
                     END;
                  END LOOP;
               END IF;
            END LOOP;

            BEGIN
               pop_quot_clauses (v_quo_code, pol_rec.pol_pro_code, TRUE);
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('Error populating mandatory clauses..');
            END;

            COMMIT;

            BEGIN
               gin_compute_prem_pkg.compute_quot_prem (v_quo_code);
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('ERROR COMPUTING PREMIUM.' || v_quo_code);
            END;
         END LOOP;
      END;*/