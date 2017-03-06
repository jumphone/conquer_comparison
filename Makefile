## Define the version of R and the path to the library
R := R_LIBS=/home/Shared/Rlib/release-3.4-lib/ /usr/local/R/R-3.3.1/bin/R CMD BATCH --no-restore --no-save

## Define the active datasets and methods
include include_methods.mk

## Plot types
PLOTTYPE := ks timing truefpr results_characterization consistency results_relativetruth results_relativetruth_all
SUMMARYTYPE := truefpr pca timing fracNA

.PHONY: all

## Define the default rule
all: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach k,$(PLOTTYPE),$(foreach X,$(DS),$k/$X_$k)))) \
$(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach k,$(PLOTTYPE),$(foreach Y,$(FILT),$(foreach X,$(DS),$k/$X_$Y_$k))))) \
$(addsuffix .pdf, $(addprefix figures/dataset_characteristics/, $(foreach X,$(DS),$X))) \
$(addsuffix .pdf, $(addprefix figures/dataset_characteristics/, $(foreach Y,$(FILT),$(foreach X,$(DS),$X_$Y)))) \
$(addsuffix .rds, $(addprefix figures/summary_crossds/summary_, $(foreach K,$(SUMMARYTYPE),$(K)))) \
$(addsuffix .rds, $(addprefix figures/summary_crossds/summary_, $(foreach Y,$(FILT),$(foreach K,$(SUMMARYTYPE),$(K)_$(Y))))) \
$(addsuffix _orig_vs_mock_summary_data.rds, $(addprefix figures/orig_vs_mock/, $(foreach X,$(Dsb),$X))) \
$(addsuffix _orig_vs_mock_summary_data.rds, $(addprefix figures/orig_vs_mock/, $(foreach Y,$(FILT),$(foreach X,$(Dsb),$X_$Y)))) \
figures/summary_crossds/summary_orig_vs_mock.rds \
$(addsuffix .rds, $(addprefix figures/summary_crossds/summary_orig_vs_mock_, $(foreach Y,$(FILT),$Y))) \
$(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach k,$(PLOTTYPE),$(foreach X,$(DSbulk),$k/$X_$k)))) \
$(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach k,$(PLOTTYPE),$(foreach Y,$(FILT),$(foreach X,$(DSbulk),$k/$X_$Y_$k))))) \
$(addsuffix .pdf, $(addprefix figures/dataset_characteristics/, $(foreach X,$(DSbulk),$X))) \
$(addsuffix .pdf, $(addprefix figures/dataset_characteristics/, $(foreach Y,$(FILT),$(foreach X,$(DSbulk),$X_$Y)))) \
$(addsuffix _bulk.rds, $(addprefix figures/summary_crossds/summary_, $(foreach K,$(SUMMARYTYPE),$(K)))) \
$(addsuffix _bulk.rds, $(addprefix figures/summary_crossds/summary_, $(foreach Y,$(FILT),$(foreach K,$(SUMMARYTYPE),$(K)_$(Y))))) \
$(addsuffix _orig_vs_mock_summary_data.rds, $(addprefix figures/orig_vs_mock/, $(foreach X,$(DSbulkb),$X))) \
$(addsuffix _orig_vs_mock_summary_data.rds, $(addprefix figures/orig_vs_mock/, $(foreach Y,$(FILT),$(foreach X,$(DSbulkb),$X_$Y)))) \
figures/summary_crossds/summary_orig_vs_mock_bulk.rds \
$(addsuffix _bulk.rds, $(addprefix figures/summary_crossds/summary_orig_vs_mock_, $(foreach Y,$(FILT),$Y)))

diffexp: $(addsuffix .rds, $(addprefix results/, $(foreach k,$(MT),$(foreach X,$(DS),$X_$k)))) \
$(addsuffix .rds, $(addprefix results/, $(foreach Y,$(FILT),$(foreach k,$(MT),$(foreach X,$(DS),$X_$k_$Y))))) \
$(addsuffix .rds, $(addprefix results/, $(foreach k,$(MTbulk),$(foreach X,$(DSbulk),$X_$k)))) \
$(addsuffix .rds, $(addprefix results/, $(foreach Y,$(FILT),$(foreach k,$(MTbulk),$(foreach X,$(DSbulk),$X_$k_$Y)))))

list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs

## Make sure no intermediate files are deleted
.SECONDARY:

## -------------------------- Generate configuration files ---------------------------- ##
## ------------------------------------------------------------------------------------ ##
define configrule
config/$(1).json: scripts/generate_config_$(1).R
	$R scripts/generate_config_$(1).R Rout/generate_config_$(1).Rout
endef
$(foreach j,$(DS),$(eval $(call configrule,$(j))))
$(foreach j,$(DSbulk),$(eval $(call configrule,$(j))))

## --------------------------- Extract sample subsets --------------------------------- ##
## ------------------------------------------------------------------------------------ ##
define subsetrule
subsets/$(1)_subsets.rds: data/$(1).rds config/$(1).json scripts/generate_subsets.R
	$R "--args config_file='config/$(1).json'" scripts/generate_subsets.R Rout/generate_subsets_$(1).Rout
endef
$(foreach j,$(DS),$(eval $(call subsetrule,$(j))))
$(foreach j,$(DSbulk),$(eval $(call subsetrule,$(j))))

## -------------------------- Generate Usoskin data set ------------------------------- ##
## ------------------------------------------------------------------------------------ ##
data/UsoskinGSE59739.rds: scripts/generate_Usoskin_mae.R data/Usoskin_External_resources_Table_1.txt
	$R scripts/generate_Usoskin_mae.R Rout/generate_Usoskin_mae.Rout

## ------------------ Define rules for differential expression ------------------------ ##
## ------------------------------------------------------------------------------------ ##
## Without filtering
define dgerule
results/$(1)_$(2).rds: scripts/apply_$(2).R scripts/prepare_mae.R scripts/run_diffexpression.R subsets/$(1)_subsets.rds data/$(1).rds
	$R "--args config_file='config/$(1).json' demethod='$(2)' filt=''" scripts/run_diffexpression.R Rout/run_diffexpression_$(1)_$(2).Rout
endef
$(foreach j,$(MT), $(foreach i,$(DS),$(eval $(call dgerule,$(i),$(j)))))
$(foreach j,$(MTbulk), $(foreach i,$(DSbulk),$(eval $(call dgerule,$(i),$(j)))))

## With filtering
define dgerulefilt
results/$(1)_$(2)_$(3).rds: scripts/apply_$(2).R scripts/prepare_mae.R scripts/run_diffexpression.R subsets/$(1)_subsets.rds data/$(1).rds
	$R "--args config_file='config/$(1).json' demethod='$(2)' filt='$(3)'" scripts/run_diffexpression.R Rout/run_diffexpression_$(1)_$(2)_$(3).Rout
endef
$(foreach k, $(FILT), $(foreach j,$(MT), $(foreach i,$(DS),$(eval $(call dgerulefilt,$(i),$(j),$(k))))))
$(foreach k, $(FILT), $(foreach j,$(MTbulk), $(foreach i,$(DSbulk),$(eval $(call dgerulefilt,$(i),$(j),$(k))))))

## ------------------ Prepare COBRAData object for evaluation ------------------------- ##
## ------------------------------------------------------------------------------------ ##
define cobrarule
figures/cobra_data/$(1)_cobra.rds: include_methods.mk scripts/prepare_cobra_for_evaluation.R \
$(addsuffix .rds, $(addprefix results/$(1)_, $(foreach Y,$(MT),$Y))) scripts/prepare_mae.R
	$R "--args demethods='${MTc}' dataset='$(1)' config_file='config/$(1).json' filt=''" scripts/prepare_cobra_for_evaluation.R Rout/prepare_cobra_for_evaluation_$(1).Rout
endef
$(foreach X,$(DS),$(eval $(call cobrarule,$(X))))

define cobrarulebulk
figures/cobra_data/$(1)_cobra.rds: include_methods.mk scripts/prepare_cobra_for_evaluation.R \
$(addsuffix .rds, $(addprefix results/$(1)_, $(foreach Y,$(MTbulk),$Y))) scripts/prepare_mae.R
	$R "--args demethods='${MTcbulk}' dataset='$(1)' config_file='config/$(1).json' filt=''" scripts/prepare_cobra_for_evaluation.R Rout/prepare_cobra_for_evaluation_$(1).Rout
endef
$(foreach X,$(DSbulk),$(eval $(call cobrarulebulk,$(X))))

define cobrarule_filt
figures/cobra_data/$(1)_$(2)_cobra.rds: include_methods.mk scripts/prepare_cobra_for_evaluation.R \
$(addsuffix _$(2).rds, $(addprefix results/$(1)_, $(foreach Y,$(MT),$Y))) scripts/prepare_mae.R
	$R "--args demethods='${MTc}' dataset='$(1)' config_file='config/$(1).json' filt='$(2)'" scripts/prepare_cobra_for_evaluation.R Rout/prepare_cobra_for_evaluation_$(1)_$(2).Rout
endef
$(foreach k,$(FILT),$(foreach X,$(DS),$(eval $(call cobrarule_filt,$(X),$(k)))))

define cobrarulebulk_filt
figures/cobra_data/$(1)_$(2)_cobra.rds: include_methods.mk scripts/prepare_cobra_for_evaluation.R \
$(addsuffix _$(2).rds, $(addprefix results/$(1)_, $(foreach Y,$(MTbulk),$Y))) scripts/prepare_mae.R
	$R "--args demethods='${MTcbulk}' dataset='$(1)' config_file='config/$(1).json' filt='$(2)'" scripts/prepare_cobra_for_evaluation.R Rout/prepare_cobra_for_evaluation_$(1)_$(2).Rout
endef
$(foreach k,$(FILT),$(foreach X,$(DSbulk),$(eval $(call cobrarulebulk_filt,$(X),$(k)))))

## --------------------------- Plots for evaluation ----------------------------------- ##
## ------------------------------------------------------------------------------------ ##
define plotrule
figures/$(2)/$(1)_$(2)_summary_data.rds: scripts/plot_evaluation.R scripts/plot_$(2).R scripts/plot_setup.R figures/cobra_data/$(1)_cobra.rds
	$R "--args dataset='$(1)' config_file='config/$(1).json' filt='' plottype='$(2)'" scripts/plot_evaluation.R Rout/plot_evaluation_$(1)_$(2).Rout
endef
$(foreach X,$(DS),$(foreach Y,$(PLOTTYPE),$(eval $(call plotrule,$(X),$(Y)))))
$(foreach X,$(DSbulk),$(foreach Y,$(PLOTTYPE),$(eval $(call plotrule,$(X),$(Y)))))

define plotrule_filt
figures/$(2)/$(1)_$(3)_$(2)_summary_data.rds: scripts/plot_evaluation.R scripts/plot_$(2).R scripts/plot_setup.R figures/cobra_data/$(1)_$(3)_cobra.rds
	$R "--args dataset='$(1)' config_file='config/$(1).json' filt='$(3)' plottype='$(2)'" scripts/plot_evaluation.R Rout/plot_evaluation_$(1)_$(3)_$(2).Rout
endef
$(foreach k,$(FILT),$(foreach X,$(DS),$(foreach Y,$(PLOTTYPE),$(eval $(call plotrule_filt,$(X),$(Y),$(k))))))
$(foreach k,$(FILT),$(foreach X,$(DSbulk),$(foreach Y,$(PLOTTYPE),$(eval $(call plotrule_filt,$(X),$(Y),$(k))))))

## -------------------- Plots for characterization of data set ------------------------ ##
## ------------------------------------------------------------------------------------ ##
define plotrule_characterization
figures/dataset_characteristics/$(1).pdf: include_methods.mk scripts/plot_characterize_dataset.R scripts/prepare_mae.R \
subsets/$(1)_subsets.rds data/$(1).rds
	$R "--args dataset='$(1)' config_file='config/$(1).json' filt=''" scripts/plot_characterize_dataset.R Rout/plot_characterize_dataset_$(1).Rout
endef
$(foreach i,$(DS),$(eval $(call plotrule_characterization,$(i))))
$(foreach i,$(DSbulk),$(eval $(call plotrule_characterization,$(i))))

define plotrule_characterization_filt
figures/dataset_characteristics/$(1)_$(2).pdf: include_methods.mk scripts/plot_characterize_dataset.R scripts/prepare_mae.R \
subsets/$(1)_subsets.rds data/$(1).rds
	$R "--args dataset='$(1)' config_file='config/$(1).json' filt='$(2)'" scripts/plot_characterize_dataset.R Rout/plot_characterize_dataset_$(1)_$(2).Rout
endef
$(foreach k,$(FILT), $(foreach i,$(DS),$(eval $(call plotrule_characterization_filt,$(i),$(k)))))
$(foreach k,$(FILT), $(foreach i,$(DSbulk),$(eval $(call plotrule_characterization_filt,$(i),$(k)))))

## -------------------- Plots for evaluation, orig vs mock ---------------------------- ##
## ------------------------------------------------------------------------------------ ##
define origvsmockrule
figures/orig_vs_mock/$(1)_orig_vs_mock_summary_data.rds: $(addsuffix .rds, $(addprefix results/$(1)_, $(foreach Y,$(MT),$Y))) \
$(addsuffix .rds, $(addprefix results/$(1)mock_, $(foreach Y,$(MT),$Y))) include_methods.mk scripts/plot_setup.R \
scripts/plot_orig_vs_mock.R scripts/plot_compare_orig_mock.R
	$R "--args demethods='${MTc}' dataset='$(1)' filt=''" scripts/plot_orig_vs_mock.R Rout/plot_orig_vs_mock_$(1).Rout
endef
$(foreach i,$(Dsb),$(eval $(call origvsmockrule,$(i))))

define origvsmockrulebulk
figures/orig_vs_mock/$(1)_orig_vs_mock_summary_data.rds: $(addsuffix .rds, $(addprefix results/$(1)_, $(foreach Y,$(MTbulk),$Y))) \
$(addsuffix .rds, $(addprefix results/$(1)mock_, $(foreach Y,$(MTbulk),$Y))) include_methods.mk scripts/plot_setup.R  \
scripts/plot_orig_vs_mock.R scripts/plot_compare_orig_mock.R
	$R "--args demethods='${MTcbulk}' dataset='$(1)' filt=''" scripts/plot_orig_vs_mock.R Rout/plot_orig_vs_mock_$(1).Rout
endef
$(foreach i,$(DSbulkb),$(eval $(call origvsmockrulebulk,$(i))))

define origvsmockrule_filt
figures/orig_vs_mock/$(1)_$(2)_orig_vs_mock_summary_data.rds: $(addsuffix _$(2).rds, $(addprefix results/$(1)_, $(foreach Y,$(MT),$Y))) \
$(addsuffix _$(2).rds, $(addprefix results/$(1)mock_, $(foreach Y,$(MT),$Y))) include_methods.mk scripts/plot_setup.R  \
scripts/plot_orig_vs_mock.R scripts/plot_compare_orig_mock.R 
	$R "--args demethods='${MTc}' dataset='$(1)' filt='$(2)'" scripts/plot_orig_vs_mock.R Rout/plot_orig_vs_mock_$(1)_$(2).Rout
endef
$(foreach k,$(FILT), $(foreach i,$(Dsb),$(eval $(call origvsmockrule_filt,$(i),$(k)))))

define origvsmockrulebulk_filt
figures/orig_vs_mock/$(1)_$(2)_orig_vs_mock_summary_data.rds: $(addsuffix _$(2).rds, $(addprefix results/$(1)_, $(foreach Y,$(MTbulk),$Y))) \
$(addsuffix _$(2).rds, $(addprefix results/$(1)mock_, $(foreach Y,$(MTbulk),$Y))) include_methods.mk scripts/plot_setup.R  \
scripts/plot_orig_vs_mock.R scripts/plot_compare_orig_mock.R 
	$R "--args demethods='${MTcbulk}' dataset='$(1)' filt='$(2)'" scripts/plot_orig_vs_mock.R Rout/plot_orig_vs_mock_$(1)_$(2).Rout
endef
$(foreach k,$(FILT), $(foreach i,$(DSbulkb),$(eval $(call origvsmockrulebulk_filt,$(i),$(k)))))

## ---------------------- Summary plots, across mock data sets ------------------------ ##
## ------------------------------------------------------------------------------------ ##
figures/summary_crossds/summary_truefpr.rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dss),truefpr/$Y_truefpr))) \
scripts/plot_summarize_datasets.R scripts/summarize_truefpr.R
	$R "--args datasets='${Dssc}' filt='' summarytype='truefpr' dtpext=''" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_truefpr.Rout

figures/summary_crossds/summary_pca.rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dss),results_characterization/$Y_results_characterization))) \
scripts/plot_summarize_datasets.R scripts/summarize_pca.R
	$R "--args datasets='${Dssc}' filt='' summarytype='pca' dtpext=''" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_pca.Rout

figures/summary_crossds/summary_timing.rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dss),timing/$Y_timing))) \
scripts/plot_summarize_datasets.R scripts/summarize_timing.R
	$R "--args datasets='${Dssc}' filt='' summarytype='timing' dtpext=''" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_timing.Rout

figures/summary_crossds/summary_fracNA.rds: $(addsuffix _cobra.rds, $(addprefix figures/, $(foreach Y,$(Dss),cobra_data/$Y))) \
scripts/plot_summarize_datasets.R scripts/summarize_fracNA.R
	$R "--args datasets='${Dssc}' filt='' summarytype='fracNA' dtpext=''" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_fracNA.Rout

define summaryrule_truefpr
figures/summary_crossds/summary_truefpr_$(1).rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dss),truefpr/$Y_$(1)_truefpr))) \
scripts/plot_summarize_datasets.R scripts/summarize_truefpr.R
	$R "--args datasets='${Dssc}' filt='$(1)' summarytype='truefpr' dtpext=''" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_truefpr_$(1).Rout
endef
$(foreach k,$(FILT),$(eval $(call summaryrule_truefpr,$(k))))

define summaryrule_pca
figures/summary_crossds/summary_pca_$(1).rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dss),results_characterization/$Y_$(1)_results_characterization))) \
scripts/plot_summarize_datasets.R scripts/summarize_pca.R
	$R "--args datasets='${Dssc}' filt='$(1)' summarytype='pca' summarytype='pca' dtpext=''" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_pca_$(1).Rout
endef
$(foreach k,$(FILT),$(eval $(call summaryrule_pca,$(k))))

define summaryrule_timing
figures/summary_crossds/summary_timing_$(1).rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dss),timing/$Y_$(1)_timing))) \
scripts/plot_summarize_datasets.R scripts/summarize_timing.R
	$R "--args datasets='${Dssc}' filt='$(1)' summarytype='timing' summarytype='timing' dtpext=''" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_timing_$(1).Rout
endef
$(foreach k,$(FILT),$(eval $(call summaryrule_timing,$(k))))

define summaryrule_fracna
figures/summary_crossds/summary_fracNA_$(1).rds: $(addsuffix _cobra.rds, $(addprefix figures/, $(foreach Y,$(Dss),cobra_data/$Y_$(1)))) \
scripts/plot_summarize_datasets.R scripts/summarize_fracNA.R
	$R "--args datasets='${Dssc}' filt='$(1)' summarytype='fracNA' summarytype='fracNA' dtpext=''" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_fracNA_$(1).Rout
endef
$(foreach k,$(FILT),$(eval $(call summaryrule_fracna,$(k))))

## ------------------ Summary plots, across mock data sets (bulk) --------------------- ##
## ------------------------------------------------------------------------------------ ##
figures/summary_crossds/summary_truefpr_bulk.rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dssbulk),truefpr/$Y_truefpr))) \
scripts/plot_summarize_datasets.R scripts/summarize_truefpr.R
	$R "--args datasets='${Dssbulk}' filt='' summarytype='truefpr' dtpext='_bulk'" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_truefpr_bulk.Rout

figures/summary_crossds/summary_pca_bulk.rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dssbulk),results_characterization/$Y_results_characterization))) \
scripts/plot_summarize_datasets.R scripts/summarize_pca.R
	$R "--args datasets='${Dssbulk}' filt='' summarytype='pca' dtpext='_bulk'" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_pca_bulk.Rout

figures/summary_crossds/summary_timing_bulk.rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dssbulk),timing/$Y_timing))) \
scripts/plot_summarize_datasets.R scripts/summarize_timing.R
	$R "--args datasets='${Dssbulk}' filt='' summarytype='timing' dtpext='_bulk'" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_timing_bulk.Rout

figures/summary_crossds/summary_fracNA_bulk.rds: $(addsuffix _cobra.rds, $(addprefix figures/, $(foreach Y,$(Dssbulk),cobra_data/$Y))) \
scripts/plot_summarize_datasets.R scripts/summarize_fracNA.R
	$R "--args datasets='${Dssbulk}' filt='' summarytype='fracNA' dtpext='_bulk'" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_fracNA_bulk.Rout

define summaryrule_truefpr_bulk
figures/summary_crossds/summary_truefpr_$(1)_bulk.rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dssbulk),truefpr/$Y_$(1)_truefpr))) \
scripts/plot_summarize_datasets.R scripts/summarize_truefpr.R
	$R "--args datasets='${Dssbulk}' filt='$(1)' summarytype='truefpr' dtpext='_bulk'" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_truefpr_$(1)_bulk.Rout
endef
$(foreach k,$(FILT),$(eval $(call summaryrule_truefpr_bulk,$(k))))

define summaryrule_pca_bulk
figures/summary_crossds/summary_pca_$(1)_bulk.rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dssbulk),results_characterization/$Y_$(1)_results_characterization))) \
scripts/plot_summarize_datasets.R scripts/summarize_pca.R
	$R "--args datasets='${Dssbulk}' filt='$(1)' summarytype='pca' summarytype='pca' dtpext='_bulk'" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_pca_$(1)_bulk.Rout
endef
$(foreach k,$(FILT),$(eval $(call summaryrule_pca_bulk,$(k))))

define summaryrule_timing_bulk
figures/summary_crossds/summary_timing_$(1)_bulk.rds: $(addsuffix _summary_data.rds, $(addprefix figures/, $(foreach Y,$(Dssbulk),timing/$Y_$(1)_timing))) \
scripts/plot_summarize_datasets.R scripts/summarize_timing.R
	$R "--args datasets='${Dssbulk}' filt='$(1)' summarytype='timing' summarytype='timing' dtpext='_bulk'" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_timing_$(1)_bulk.Rout
endef
$(foreach k,$(FILT),$(eval $(call summaryrule_timing_bulk,$(k))))

define summaryrule_fracna_bulk
figures/summary_crossds/summary_fracNA_$(1)_bulk.rds: $(addsuffix _cobra.rds, $(addprefix figures/, $(foreach Y,$(Dssbulk),cobra_data/$Y_$(1)))) \
scripts/plot_summarize_datasets.R scripts/summarize_fracNA.R
	$R "--args datasets='${Dssbulk}' filt='$(1)' summarytype='fracNA' summarytype='fracNA' dtpext='_bulk'" scripts/plot_summarize_datasets.R Rout/plot_summarize_datasets_fracNA_$(1)_bulk.Rout
endef
$(foreach k,$(FILT),$(eval $(call summaryrule_fracna_bulk,$(k))))

## --------------------------- Summary plots, orig vs mock ---------------------------- ##
## ------------------------------------------------------------------------------------ ##
figures/summary_crossds/summary_orig_vs_mock.rds: $(addsuffix _orig_vs_mock_summary_data.rds, $(addprefix figures/orig_vs_mock/, $(foreach Y,$(Dsb),$Y))) \
scripts/plot_summarize_orig_vs_mock.R
	$R "--args datasets='${Dsbc}' filt='' dtpext=''" scripts/plot_summarize_orig_vs_mock.R Rout/plot_summarize_orig_vs_mock.Rout

figures/summary_crossds/summary_orig_vs_mock_bulk.rds: $(addsuffix _orig_vs_mock_summary_data.rds, $(addprefix figures/orig_vs_mock/, $(foreach Y,$(DSbulkb),$Y))) \
scripts/plot_summarize_orig_vs_mock.R
	$R "--args datasets='${DSbulkb}' filt='' dtpext='_bulk'" scripts/plot_summarize_orig_vs_mock.R Rout/plot_summarize_orig_vs_mock_bulk.Rout

define plotrule_summary_origvsmock
figures/summary_crossds/summary_orig_vs_mock_$(1).rds: $(addsuffix _$(1)_orig_vs_mock_summary_data.rds, $(addprefix figures/orig_vs_mock/, $(foreach Y,$(Dsb),$Y))) \
scripts/plot_summarize_orig_vs_mock.R
	$R "--args datasets='${Dsbc}' filt='$(1)' dtpext=''" scripts/plot_summarize_orig_vs_mock.R Rout/plot_summarize_$(1)_orig_vs_mock.Rout
endef
$(foreach k,$(FILT),$(eval $(call plotrule_summary_origvsmock,$(k))))

define plotrule_summary_origvsmockbulk
figures/summary_crossds/summary_orig_vs_mock_$(1)_bulk.rds: $(addsuffix _$(1)_orig_vs_mock_summary_data.rds, $(addprefix figures/orig_vs_mock/, $(foreach Y,$(DSbulkb),$Y))) \
scripts/plot_summarize_orig_vs_mock.R
	$R "--args datasets='${DSbulkb}' filt='$(1)' dtpext='_bulk'" scripts/plot_summarize_orig_vs_mock.R Rout/plot_summarize_$(1)_orig_vs_mock_bulk.Rout
endef
$(foreach k,$(FILT),$(eval $(call plotrule_summary_origvsmockbulk,$(k))))


