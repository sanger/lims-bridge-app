PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;

CREATE TABLE "sample_manifest_templates" (
  "id" INTEGER PRIMARY KEY,
  "name" varchar(255) DEFAULT NULL,
  "asset_type" varchar(255) DEFAULT NULL,
  "path" varchar(255) DEFAULT NULL,
  "default_values" varchar(255) DEFAULT NULL,
  "cell_map" varchar(255) DEFAULT NULL
);

CREATE TABLE "sample_manifests" (
  "id" INTEGER PRIMARY KEY,
  "created_at" datetime DEFAULT NULL,
  "updated_at" datetime DEFAULT NULL,
  "study_id" int(11) DEFAULT NULL,
  "project_id" int(11) DEFAULT NULL,
  "supplier_id" int(11) DEFAULT NULL,
  "count" int(11) DEFAULT NULL,
  "uploaded_file" longblob,
  "generated_file" longblob,
  "asset_type" varchar(255) DEFAULT NULL,
  "last_errors" text,
  "state" varchar(255) DEFAULT NULL,
  "barcodes" text,
  "user_id" int(11) DEFAULT NULL
);

CREATE TABLE "sample_metadata" (
  "id" INTEGER PRIMARY KEY,
  "sample_id" int(11) DEFAULT NULL,
  "organism" varchar(255) DEFAULT NULL,
  "gc_content" varchar(255) DEFAULT NULL,
  "cohort" varchar(255) DEFAULT NULL,
  "gender" varchar(255) DEFAULT NULL,
  "country_of_origin" varchar(255) DEFAULT NULL,
  "geographical_region" varchar(255) DEFAULT NULL,
  "ethnicity" varchar(255) DEFAULT NULL,
  "dna_source" varchar(255) DEFAULT NULL,
  "volume" varchar(255) DEFAULT NULL,
  "supplier_plate_id" varchar(255) DEFAULT NULL,
  "mother" varchar(255) DEFAULT NULL,
  "father" varchar(255) DEFAULT NULL,
  "replicate" varchar(255) DEFAULT NULL,
  "sample_public_name" varchar(255) DEFAULT NULL,
  "sample_common_name" varchar(255) DEFAULT NULL,
  "sample_strain_att" varchar(255) DEFAULT NULL,
  "sample_taxon_id" int(11) DEFAULT NULL,
  "sample_ebi_accession_number" varchar(255) DEFAULT NULL,
  "sample_sra_hold" varchar(255) DEFAULT NULL,
  "sample_reference_genome_old" varchar(255) DEFAULT NULL,
  "sample_description" text,
  "sibling" varchar(255) DEFAULT NULL,
  "is_resubmitted" tinyint(1) DEFAULT NULL,
  "date_of_sample_collection" varchar(255) DEFAULT NULL,
  "date_of_sample_extraction" varchar(255) DEFAULT NULL,
  "sample_extraction_method" varchar(255) DEFAULT NULL,
  "sample_purified" varchar(255) DEFAULT NULL,
  "purification_method" varchar(255) DEFAULT NULL,
  "concentration" varchar(255) DEFAULT NULL,
  "concentration_determined_by" varchar(255) DEFAULT NULL,
  "sample_type" varchar(255) DEFAULT NULL,
  "sample_storage_conditions" varchar(255) DEFAULT NULL,
  "supplier_name" varchar(255) DEFAULT NULL,
  "reference_genome_id" int(11) DEFAULT '1',
  "genotype" varchar(255) DEFAULT NULL,
  "phenotype" varchar(255) DEFAULT NULL,
  "age" varchar(255) DEFAULT NULL,
  "developmental_stage" varchar(255) DEFAULT NULL,
  "cell_type" varchar(255) DEFAULT NULL,
  "disease_state" varchar(255) DEFAULT NULL,
  "compound" varchar(255) DEFAULT NULL,
  "dose" varchar(255) DEFAULT NULL,
  "immunoprecipitate" varchar(255) DEFAULT NULL,
  "growth_condition" varchar(255) DEFAULT NULL,
  "rnai" varchar(255) DEFAULT NULL,
  "organism_part" varchar(255) DEFAULT NULL,
  "time_point" varchar(255) DEFAULT NULL,
  "disease" varchar(255) DEFAULT NULL,
  "subject" varchar(255) DEFAULT NULL,
  "treatment" varchar(255) DEFAULT NULL,
  "created_at" datetime DEFAULT NULL,
  "updated_at" datetime DEFAULT NULL,
  "donor_id" varchar(255) DEFAULT NULL
);

CREATE TABLE "sample_registrars" (
  "id" INTEGER PRIMARY KEY,
  "study_id" int(11) DEFAULT NULL,
  "user_id" int(11) DEFAULT NULL,
  "sample_id" int(11) DEFAULT NULL,
  "sample_tube_id" int(11) DEFAULT NULL,
  "asset_group_id" int(11) DEFAULT NULL
);

CREATE TABLE "samples" (
  "id" INTEGER PRIMARY KEY,
  "name" varchar(255) DEFAULT NULL,
  "new_name_format" tinyint(1) DEFAULT '1',
  "created_at" datetime DEFAULT NULL,
  "updated_at" datetime DEFAULT NULL,
  "sanger_sample_id" varchar(255) DEFAULT NULL,
  "sample_manifest_id" int(11) DEFAULT NULL,
  "control" tinyint(1) DEFAULT NULL,
  "empty_supplier_sample_name" tinyint(1) DEFAULT '0',
  "updated_by_manifest" tinyint(1) DEFAULT '0',
  "consent_withdrawn" tinyint(1) NOT NULL DEFAULT '0'
);

CREATE TABLE "sanger_sample_ids" (
  "id" INTEGER PRIMARY KEY
);

CREATE TABLE "assets" (
  "id" INTEGER PRIMARY KEY,
  "name" varchar(255) DEFAULT NULL,
  "value" varchar(255) DEFAULT NULL,
  "descriptors" text,
  "descriptor_fields" text,
  "sti_type" varchar(50) DEFAULT NULL,
  "barcode" varchar(255) DEFAULT NULL,
  "qc_state" varchar(20) DEFAULT NULL,
  "resource" tinyint(1) DEFAULT NULL,
  "created_at" datetime DEFAULT NULL,
  "updated_at" datetime DEFAULT NULL,
  "map_id" int(11) DEFAULT NULL,
  "size" int(11) DEFAULT NULL,
  "closed" tinyint(1) DEFAULT '0',
  "public_name" varchar(255) DEFAULT NULL,
  "archive" tinyint(1) DEFAULT NULL,
  "external_release" tinyint(1) DEFAULT NULL,
  "two_dimensional_barcode" varchar(255) DEFAULT NULL,
  "plate_purpose_id" int(11) DEFAULT NULL,
  "volume" decimal(10,2) DEFAULT NULL,
  "barcode_prefix_id" int(11) DEFAULT NULL,
  "concentration" decimal(18,8) DEFAULT NULL,
  "legacy_sample_id" int(11) DEFAULT NULL,
  "legacy_tag_id" int(11) DEFAULT NULL
);

CREATE TABLE "maps" (
  "id" INTEGER PRIMARY KEY,
  "description" varchar(4) DEFAULT NULL,
  "asset_size" int(11) DEFAULT NULL,
  "location_id" int(11) DEFAULT NULL,
  "row_order" int(11) DEFAULT NULL,
  "column_order" int(11) DEFAULT NULL
);

CREATE TABLE "well_attributes" (
  "id" INTEGER PRIMARY KEY,
  "well_id" int(11) DEFAULT NULL,
  "gel_pass" varchar(20) DEFAULT NULL,
  "concentration" float DEFAULT NULL,
  "current_volume" float DEFAULT NULL,
  "buffer_volume" float DEFAULT NULL,
  "requested_volume" float DEFAULT NULL,
  "picked_volume" float DEFAULT NULL,
  "created_at" datetime DEFAULT NULL,
  "updated_at" datetime DEFAULT NULL,
  "pico_pass" varchar(255) NOT NULL DEFAULT 'ungraded',
  "sequenom_count" int(11) DEFAULT NULL,
  "study_id" varchar(255) DEFAULT NULL,
  "gender_markers" varchar(255) DEFAULT NULL,
  "gender" varchar(255) DEFAULT NULL,
  "measured_volume" float DEFAULT NULL
);

CREATE TABLE "asset_links" (
  "id" INTEGER PRIMARY KEY,
  "ancestor_id" int(11) DEFAULT NULL,
  "descendant_id" int(11) DEFAULT NULL,
  "direct" tinyint(1) DEFAULT NULL,
  "count" int(11) DEFAULT NULL,
  "created_at" datetime NOT NULL,
  "updated_at" datetime NOT NULL
);

CREATE TABLE "container_associations" (
  "id" INTEGER PRIMARY KEY,
  "container_id" int(11) NOT NULL,
  "content_id" int(11) NOT NULL
);

CREATE TABLE "aliquots" (
  "id" INTEGER PRIMARY KEY,
  "receptacle_id" int(11) NOT NULL,
  "study_id" int(11) DEFAULT NULL,
  "project_id" int(11) DEFAULT NULL,
  "library_id" int(11) DEFAULT NULL,
  "sample_id" int(11) NOT NULL,
  "tag_id" int(11) DEFAULT NULL,
  "library_type" varchar(255) DEFAULT NULL,
  "insert_size_from" int(11) DEFAULT NULL,
  "insert_size_to" int(11) DEFAULT NULL,
  "created_at" datetime DEFAULT NULL,
  "updated_at" datetime DEFAULT NULL,
  "bait_library_id" int(11) DEFAULT NULL
);

CREATE TABLE "barcode_prefixes" (
  "id" INTEGER PRIMARY KEY,
  "prefix" varchar(255) DEFAULT NULL
);

CREATE TABLE "studies" (
  "id" INTEGER PRIMARY KEY,
  "name" varchar(255) NOT NULL
);

CREATE TABLE "study_metadata" (
  "id" INTEGER PRIMARY KEY,
  "study_id" int(11) default null,
  "study_name_abbreviation" varchar(255) NOT NULL
);

CREATE TABLE "study_samples" (
  "id" INTEGER PRIMARY KEY,
  "study_id" int(11) NOT NULL,
  "sample_id" int(11) NOT NULL,
  "created_at" datetime DEFAULT NULL,
  "updated_at" datetime DEFAULT NULL
);

CREATE TABLE "locations" (
  "id" INTEGER PRIMARY KEY,
  "name" varchar(255) NOT NULL
);

CREATE TABLE "location_associations" (
  "id" INTEGER PRIMARY KEY,
  "locatable_id" int(11) NOT NULL,
  "location_id" int(11) NOT NULL
);

CREATE TABLE "requests" (
  "id" INTEGER PRIMARY KEY,
  "asset_id" int(11) NOT NULL,
  "initial_study_id" int(11) NULL,
  "target_asset_id" int(11) NULL,
  "sti_type" varchar(255) NOT NULL,
  "state" varchar(255) NOT NULL,
  "request_type_id" int(11) DEFAULT NULL,
  "created_at" datetime DEFAULT NULL,
  "updated_at" datetime DEFAULT NULL
);

CREATE TABLE "uuids" (
  "id" INTEGER PRIMARY KEY,
  "resource_type" varchar(128) NOT NULL,
  "resource_id" int(11) NOT NULL,
  "external_id" varchar(36) NOT NULL
);

COMMIT;
