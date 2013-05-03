module Lims::BridgeApp
  module SampleManagement
    module SequencescapeMapper

      MAPPING = { 
        :samples => {
          :sanger_sample_id => :sanger_sample_id,
          :name => :common_name
        },
        :sample_metadata => {
          :organism => nil,
          :gc_content => :gc_content,
          :cohort => :cohort,
          :gender => :gender,
          :country_of_origin => nil,
          :geographical_region => nil,
          :ethnicity => nil,
          :dna_source => :sample_source,
          :volume => :volume,
          :supplier_plate_id => nil,
          :mother => :mother,
          :father => :father,
          :replicate => nil,
          :sample_public_name => :public_name,
          :sample_common_name => :common_name,
          :sample_strain_att => nil,
          :sample_taxon_id => :taxon_id,
          :sample_ebi_accession_number => :ebi_accession_number,
          :sample_sra_hold => nil,
          :sample_reference_genome_old => nil,
          :sample_description => nil,
          :sibling => :sibling,
          :is_resubmitted => :is_re_submitted_sample,
          :date_of_sample_collection => :date_of_sample_collection,
          :date_of_sample_extraction => :__component__date_of_sample_extraction,
          :sample_extraction_method => :__component__extraction_method,
          :sample_purified => :__component__sample_purified,
          :purification_method => nil,
          :concentration => :__component__concentration,
          :concentration_determined_by => :__component__concentration_determined_by_which_method,
          :sample_type => :sample_type,
          :sample_storage_conditions => :storage_conditions,
          :supplier_name => :supplier_sample_name,
          :reference_genome_id => nil,
          :genotype => nil,
          :phenotype => nil,
          :age => nil,
          :developmental_stage => nil,
          :cell_type => nil,
          :disease_state => nil,
          :compound => nil,
          :dose => nil,
          :immunoprecipitate => nil,
          :growth_condition => nil,
          :rnai => nil,
          :organism_part => nil,
          :time_point => nil,
          :disease => nil,
          :subject => nil,
          :treatment => nil
        }
      }

    end
  end
end
