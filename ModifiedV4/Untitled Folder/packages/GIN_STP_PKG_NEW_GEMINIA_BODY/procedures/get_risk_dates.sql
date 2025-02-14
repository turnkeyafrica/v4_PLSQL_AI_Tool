PROCEDURE get_risk_dates (
        v_scl_code                 IN     NUMBER,
        v_covt_code                IN     NUMBER,
        v_pol_tot_instlmt          IN     NUMBER,
        v_pro_expiry_period        IN     VARCHAR2,
        v_pol_cover_from           IN     DATE,
        v_pol_cover_to             IN     DATE,
        v_increment                IN     VARCHAR2,
        v_increment_by             IN     NUMBER,
        v_susp_reinstate           IN     VARCHAR2,
        v_susp_reinst_type         IN     VARCHAR2,
        v_risk_pymt_install_pcts   IN OUT VARCHAR2,
        v_wef_date                 IN OUT DATE,
        v_wet_date                 IN OUT DATE,
        v_install_period           IN OUT NUMBER,
        v_cover_days               IN OUT NUMBER,
        v_susp_wef                 IN OUT DATE,
        v_susp_wet                 IN OUT DATE,
        v_new_pol_wet                 OUT DATE,
        v_pol_install_wet          IN OUT DATE,
        v_pol_loaded                      VARCHAR2 DEFAULT 'N',
        v_ipu_status               IN     VARCHAR2 DEFAULT NULL)
    IS
        v_cvt_install_type          gin_subclass_cover_types.sclcovt_install_type%TYPE;
        v_cvt_max_installs          gin_subclass_cover_types.sclcovt_max_installs%TYPE;
        v_cvt_pymt_install_pcts     gin_subclass_cover_types.sclcovt_pymt_install_pcts%TYPE;
        v_cvt_install_periods       gin_subclass_cover_types.sclcovt_install_periods%TYPE;
        v_install_pct               NUMBER;
        v_pymnt_tot_instlmt         NUMBER;
        v_suspend_days              NUMBER;
        v_install_days              NUMBER;
        v_max_installs              NUMBER;
        v_months_added              NUMBER;
        v_day                       NUMBER;
        v_month                     NUMBER;
        v_year                      NUMBER;
        v_mnth                      NUMBER;
        v_add_days                  NUMBER;
        v_reinsdayspremsubs_param   NUMBER;
    --v_pol_install_wet DATE;
    BEGIN
        --raise_error ('Error getting cover type details..');
        BEGIN
            SELECT sclcovt_install_type,
                   sclcovt_max_installs,
                   sclcovt_pymt_install_pcts,
                   sclcovt_install_periods
              INTO v_cvt_install_type,
                   v_cvt_max_installs,
                   v_cvt_pymt_install_pcts,
                   v_cvt_install_periods
              FROM gin_subclass_cover_types
             WHERE     sclcovt_covt_code = v_covt_code
                   AND sclcovt_scl_code = v_scl_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error getting cover type details..');
        END;