.PHONY: migrate_test serve
migrate_test:
	rm test.db ; cat db/test/sequencescape_test_schema.sql | sqlite3 test.db;
	cat db/test/sequencescape_test_seeds.sql | sqlite3 test.db
